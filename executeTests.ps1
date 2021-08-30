param (
    [switch] $Publish,
    [switch] $OutputXml,
    [switch] $NoCodeCoverage
)

Clear-Host

If (!(Get-Module Pester)) {
    if (!(get-module pester -ListAvailable)) {
        "Installing Pester (unit test framework)"
        Install-Module -Name Pester -Force
    }
}

$psRunlistDevPath = $PSScriptRoot

$functions = Get-Item Function:
Set-Location $PSScriptRoot
$pwd = Get-Location

try {
    Get-Item $PSScriptRoot/PSRunlist/*.ps1 |
        ForEach-Object {
            . $_
        }

    $cmd = "Invoke-Pester '$psRunlistDevPath/Tests' -PassThru"
    if (!$NoCodeCoverage) {
        $cmd += " -CodeCoverage (Get-ChildItem -Path $psRunlistDevPath/PSRunlist/*.ps1 -Exclude 'New-DynamicParam.ps1').FullName"
    }

    if ($OutputXml) {
        $date = Get-Date -Format yyyyMMddTHHmmss
        $cmd += " -OutputFile ""$psRunlistDevPath/Tests/Results/$date.xml"" -OutputFormat NUnitXml"
    }

    $results = Invoke-Expression $cmd

    if ( $results.FailedCount -eq 0 -and $publish) {
        'Importing PSRunlist to PS module path' | Write-Host

        # Get the module path which is a bit different for linux vs windows
        $modulePath = $env:PSModulePath -split ";" | Select-Object -First 1
        if ($null -eq $env:OS) { # HACK this is a linux box
            $modulePath = $env:PSModulePath -split ":" | Select-Object -First 1
        }

        $modulePath = "$modulePath/PSRunlist"

        # If the module exists, delete it
        If (Test-Path $modulePath) {
          Remove-Item $modulePath -Recurse -Force
        }

        # Copy the runbook to the module directory
        Copy-Item -Path $psRunlistDevPath/PSRunlist -Destination $modulePath -Recurse
        If (Get-Module PSRunlist) {
            Remove-Module PSRunlist -Force
        }
    }
}

finally {
    (Get-Item Function:)[0] | ForEach-Object {
        $name = $_.Name
        if ((($functions | select-object Name).Name -contains $name) -eq $false) {
            Remove-Item Function:\$name
        }
    }
    Set-Location $pwd
}
