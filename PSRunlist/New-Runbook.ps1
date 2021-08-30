Function New-Runbook {
    param(
        [Parameter(Mandatory=$true)]
        [string]$Path
    )

    # Base runbook object from runbook.json
    $runbook = Get-Content $path -Raw | ConvertFrom-Json

    # Verify that all properties that *might* be in the runbook.json file are in the runbook object
    $kvProperties = @(
        @("parameters", @()),
        @("dependencies", @()),
        @("runbooks", @{}),
        @("autorun", @())
    ) | ForEach-Object {
        If (! ($runbook | Get-Member -MemberType NoteProperty -Name $_[0])) {
            $runbook | Add-Member -MemberType NoteProperty -Name $_[0] -Value $_[1]
        }
    }

    if ($runbook.runbooks -isnot [hashtable]) {
        $runbook.runbooks = $runbook.runbooks | Convert-PSObjectToHashtable
    }

    # Path Property
    $runbook |
        Add-Member -MemberType NoteProperty -Name path -Value (Split-Path $Path -Parent)

    # Name Property
    $runbook |
        Add-Member -MemberType ScriptProperty -Name name -Value {
            Split-Path $this.Path -Leaf
        }

    # Parent Property
    $runbook |
        Add-Member -MemberType ScriptProperty -Name Parent -Value {
            $parent = $this.Path
            while ($true) {
                $parent = Split-Path -Path $parent
                If ($parent -eq '') { return $null }
                If (Test-Path -Path "$parent\runbook.json") {
                    $parent = Split-Path $parent -Leaf
                    break
                }
            }

            return $parent
        }

    # Add runbooks to runbooks property
    if (Test-Path (Join-Path $runbook.path -ChildPath runbook)) {
        Join-Path $runbook.path -ChildPath runbook | Get-Item | Get-ChildItem -File -Filter '*.ps1' | ForEach-Object {
            If (! $runbook.runbooks[$_.BaseName]) {
                $runbook.runbooks[$_.BaseName] = $_.BaseName
            }
            else {
                throw "`t`t Cannot add recipe $($_.BaseName) to runbook [$($runbook.Name)] because already defined in runbook.json"
            }
        }
    }

    # Add scripts to scripts property
    $runbook |
        Add-Member -MemberType ScriptProperty -Name scripts -Value {
            $scriptFiles = @()
            $scriptFilesDirectory = Join-Path $this.path -ChildPath scripts
            If (Test-Path $scriptFilesDirectory) {
                Join-Path $this.path -ChildPath scripts | Get-Item | Get-ChildItem -File -Filter '*.ps1' | ForEach-Object {
                    $scriptFiles += $_.FullName
                }
            }
            return $scriptFiles
        }

    # return the file paths for the attribute files
    $runbook |
        Add-Member -MemberType ScriptMethod -Name attributeFiles -Value {
            $attributeFiles = @()
            $attributesDirectory = Join-Path $this.path -ChildPath attributes
            If (Test-Path $attributesDirectory) {
                Join-Path $this.path -ChildPath attributes | Get-Item | Get-ChildItem -File -Include '*.json', '*.yaml' | ForEach-Object {
                    $attributeFiles += $_.FullName
                }
            }
            return $attributeFiles
        }

    # return the file paths for the parameter files
    $runbook |
        Add-Member -MemberType ScriptMethod -Name parameterFiles -Value {
            $parameters = @{}
            $parameterDirectory = Join-Path $this.path -ChildPath parameters
            If (Test-Path $parameterDirectory) {
                $parameterDirectory | Get-Item | Get-ChildItem -Directory | ForEach-Object {
                    $parameterFiles = @{}
                    $_ | Get-ChildItem -File -Include '*.json', '*.yaml' | ForEach-Object {
                        $parameterFiles[$_.BaseName] = $_.FullName
                    }
                    $parameters[$_.Name] = [PSCustomObject]$parameterFiles
                }
            }
            return [PSCustomObject]$parameters
        }

    # Add the additional file paths as properties of the runbook
    $runbook |
        Add-Member -MemberType ScriptProperty -Name FileSystem -Value {
            function Add-Properties {
                param (
                    $FileSystemObject,
                    $Parent
                )

                if ($fileSystemObject -is [System.IO.DirectoryInfo]) {
                    $childObj = new-object PSObject
                    $s = Add-Member -InputObject $parent -MemberType NoteProperty -Name $fileSystemObject.Name -Value $childObj -PassThru
                    $s | Add-Member -MemberType NoteProperty -Name '_Value_' -Value $fileSystemObject.FullName -force # To output the path

                    Get-ChildItem -Path $fileSystemObject.FullName | ForEach-Object {
                        $child = $_
                        Add-Properties -FileSystemObject $child -Parent $childObj
                    }
                }
                else {
                    Add-Member -InputObject $parent -MemberType NoteProperty -Name $fileSystemObject.Name -Value $fileSystemObject.FullName
                }
            }

            $tree = new-object PSObject
            Get-ChildItem -Path $this.Path | Foreach-Object {
                $fileSystemObject = $_
                Add-Properties -FileSystemObject $fileSystemObject -Parent $tree
            }

            return $tree
        }

    return $runbook
}
