


Function New-Runlist {
    [CmdletBinding()]
    param(
        [Parameter(ParameterSetName='List')]
        [switch] $ListAvailable,

        [Parameter(ParameterSetName='Runlist')]
        [ValidateScript(
            {
                $validateSet = Get-RunbookPlays
                if ($validateSet -contains $_) { $true }
                else {
                    "No runbooks were successfully loaded based on -Names parameter.  Valid values are: " | Write-Host -ForegroundColor Yellow
                    $validateSet | Sort-Object | ForEach-Object {
                        $_ | Write-Host -ForegroundColor Yellow
                    }
                    $true
                }
            }
        )]
        [Array]$Names,

        [Parameter(Mandatory=$false, ParameterSetName='Runlist')]
        [string]$AdditionalConfig
    )

    DynamicParam {
        Set-StrictMode -Off
        $INIT_FILE_NAME = 'runbook.json'
        $ErrorActionPreference = 'Continue'
        $Script:allInitFiles = $null

        if ($names) {
            $dictionary = [System.Management.Automation.RuntimeDefinedParameterDictionary]::new()

            # Load the runbooks that will be executed, and any dependencies
            [string[]]$runbookInitFiles = @()
            $names | ForEach-Object {
                $name = $_
                $runbookName = ($name -split '::')[0]
                $runbookInitFiles += Load-RunbookInitFiles -runbookName $runbookName
            }

            # Get the defined parameters from all loaded runbooks and add them as dynamic parameters
            $runbookInitFiles | ForEach-Object {
                $runbook = New-Runbook -Path $_
                if ($runbook.Parameters) {
                    $runbook.parameters | ForEach-Object {
                        $parameter = $_ | Convert-PSObjectToHashtable
                        $parameter['ParameterSetName'] = 'Runlist'
                        if ($null -eq $dictionary[$parameter.Name]) {
                            New-DynamicParam @parameter -HelpMessage "This parameter is required by: $($runbook.name)" -DPDictionary $dictionary
                        }
                        else {
                            $param = $dictionary[$parameter.Name]
                            if ($parameter.Mandatory -eq $true) {
                              $param.Attributes[0].Mandatory = $true
                            }
                            $dictionary[$parameter.Name].Attributes[0].HelpMessage += ", $($runbook.name)"
                        }
                    }
                }
            }

            return $dictionary
        }
    }

    begin {
        Set-StrictMode -Off
        $INIT_FILE_NAME = 'runbook.json'
        $Script:allInitFiles = $null

        If ($PSBoundParameters['Debug']) {
            $DebugPreference = 'Continue'
        }

        "-----------------" | Write-Debug
        "Begin New-Runlist" | Write-Debug
        "-----------------" | Write-Debug

        If ($ListAvailable) {
            "Returning list of runbookplays based on -ListAvailable parameter." | Write-Debug
            $plays = Get-RunbookPlays -describe
            "Valid values for -Names parameter are: " | Write-Host -ForegroundColor Green
            $plays | ForEach-Object {
                $_| Write-Host -ForegroundColor Yellow
            }

            return
        }

        $Names | ForEach-Object {
            $name = $_
            if ([String]::IsNullOrWhiteSpace($name)) {
                "Names parameter cannot contain nulls or blanks" | Write-Host -ForegroundColor Red
                break
            }
        }
        $runlist = [PSCustomObject]@{
            "runbooks" = @{};
            "runbookArray" = @();
            "runlist" = @();
            "attributes" = [PSCustomObject]@{}
        }

    "Add dynamic parameters to the attributes collection." | Write-Debug
        # Only the dynamic parameters will be added to the attributes collection
        $parameters = @{}
        $PSBoundParameters.Keys | ForEach-Object {
            $parameter = $_
            if ($parameter -notin 'names', 'additionalconfig') {
                $parameters[$_] = $PSBoundParameters[$_]
            }
        }

        $parameters.Keys | ForEach-Object {
            "`t $_" | Write-Debug
            $key = $_
            $value = $parameters[$key] | ConvertTo-Json
            $parameterAttributes = "{`"$key`": $value}" | ConvertFrom-Json
            $runlist.attributes = Merge-HashTable -base $runlist.attributes -extend $parameterAttributes -attributeLevel default_attributes
        }

    "Load the runlist" | Write-Debug
        $names | ForEach-Object {
            $runbookName, $recipeName = $_ -Split '::'
            if (! $recipeName) { $recipeName = 'default' }
            "`t Adding recipe $runbookName::$recipeName to runlist" | Write-Debug
            $runlist.runlist += "$runbookName::$recipeName"
        }

    "Load runbooks array" | Write-Debug
        [string[]]$runbookInitFiles = @()

        # Load the runbooks that will be executed, and any dependencies
        $names | ForEach-Object {
            $name = $_
            $runbookName = ($name -split '::')[0]
            $runbookInitFiles += Load-RunbookInitFiles -runbookName $runbookName
        }

        # If no runbooks were loaded return an empty object
        #If ($runbookInitFiles.Count -eq 0) { return $null }

        $runbookInitFiles | ForEach-Object {
            $runbook = New-Runbook -Path $_
            "`t Adding runbook $($runbook.Name)" | Write-Debug
            $runlist.runbookArray += $runbook.name
            $runlist.runbooks[$runbook.name] = $runbook
        }

    "Import Attributes" | Write-Debug
        $baseAttributeLevels = @("default_attributes", "override_attributes")
        $attributeLevelArray = $baseAttributeLevels
        $parameters.GetEnumerator() | ForEach-Object {
          $parameterName = $_.Name
          $parameterValue = $_.Value
          $attributeLevelArray += "${parameterName}:${parameterValue}"
        }

        $attributeLevelArray | ForEach-Object {
            $attributeLevel = $_
            "`t Loading $attributeLevel" | Write-Debug
            $runlist.runbookArray | ForEach-Object {
                $runbook = $runlist.runbooks[$_]

                # parameter processing
                $parameters.GetEnumerator() | ForEach-Object {
                    $parameterName = $_.Name
                    $parameterValue = $_.Value
                    $parameterFilePath = $runbook.parameterFiles().$parameterName.$parameterValue
                    if ($parameterFilePath) {
                        "`t`t Loading parameter file $($runbook.name)/parameters/$parameterName/$parameterValue" | Write-Debug
                        $runlist.attributes = Import-Attributes -attributes $runlist.attributes -attributeFile $parameterFilePath -attributeLevel $attributeLevel
                    }
                }

                # runbook attribute processing
                if ($attributeLevel -in $baseAttributeLevels) {
                  $runbook.attributeFiles() | ForEach-Object {
                      $attributeFilePath = $_
                      $attributeFile = Split-Path -Path $attributeFilePath -Leaf
                      "`t`t Loading attribute file $($runbook.name)/attributes/$attributeFile" | Write-Debug
                      $runlist.attributes = Import-Attributes -attributes $runlist.attributes -attributeFile $attributeFilePath -attributeLevel $attributeLevel
                  }
                }
            }
        }

        # additional config processing
        if ($additionalConfig) {
          $additionalConfig | ForEach-Object {
              $config = $_
              $attributeFileContent = $config

              # If AdditionalConfig is a path, load the file into the $attributes
              if (Test-Path -Path $config) {
                  $attributeFileContent = $config
                  "`t Loading additional config file : $config" | Write-Debug
              }
              else {
                  "`t Loading additional config from json in command line" | Write-Debug
                  $attributeFileContent = ($attributeFileContent | ConvertFrom-Json) | ConvertTo-Json -Depth 100
              }

              if ($attributeFileContent) {
                $runlist.attributes = Import-Attributes -attributes $runlist.attributes -attributeFile $attributeFileContent -attributeLevel 'override_attributes'
              }
          }
      }

        # Search attributes for strings that are valid script blocks based on { and } wrappers
        $attributes = $runlist.attributes
        $runlist.attributes | Parse-Commands
        return $runlist
    }
}

Function Load-RunbookInitFiles {
    param (
        [string]$runbookName
    )
    if (! $Script:allInitFiles) {
        $Script:allInitFiles = @{}
        Get-ChildItem -Recurse -File -Filter $INIT_FILE_NAME | ForEach-Object {
            $runbookPath = $_.FullName
            $name = Split-Path -Path $_.DirectoryName -Leaf
            $script:allInitFiles[$name] = $runbookPath
        }
    }

    [string[]]$runbookInitFiles = @()
    $runbookname = ($runbookName -split '::')[0]
    If ($script:allInitFiles.ContainsKey($runbookName)) {
        $initFilePath = $Script:allinitFiles[$runbookName]
        $script:allInitFiles.Remove($runbookName)
        $runbook = New-Runbook -Path $initFilePath
        If ($runbook.Parent) {
            $runbookInitFiles += Load-RunbookInitFiles -runbookName $runbook.Parent
        }

        $runbook.runbooks.Keys | ForEach-Object {
            $runbookArray = $runbook.runbooks[$_]
            if ($runbookArray -is [Array]) {
                $runbookArray | ForEach-Object {
                    $runbookInitFiles += Load-RunbookInitFiles -runbookName $_
                }
            }
        }

        $runbook.dependencies + $runbook.autorun | ForEach-Object {
            $runbookName = $_
            $runbookInitFiles += Load-RunbookInitFiles -runbookName $_
        }

        $runbookInitFiles += $initFilePath
    }

    return $runbookInitFiles
}

Function Get-RunbookPlays {
    param (
        [switch]$describe
    )
    $INIT_FILE_NAME = 'runbook.json'
    $runbookPlays = @()
    Get-ChildItem -Recurse -File -Filter $INIT_FILE_NAME | ForEach-Object {
        $runbookPath = $_.FullName
        $runbook = New-Runbook $runbookPath
        $runbook.runbooks.Keys | ForEach-Object {
            $play = $_
            $text = $play
            if ($describe -and $runbook.runbooks[$play] -is 'Array') {
                $text += "`n`t" + ($runbook.runbooks[$play] -join "`n`t")
            }
            $runbookPlays += "$($runbook.Name)::$text"
            if ($play -eq 'default') { $runbookPlays += $runbook.Name }
        }
    }

    return $runbookPlays | Sort-Object
}
