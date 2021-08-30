
Describe 'New-Runlist' {
    It 'Expects -Names parameter to not be null or blank' {
        Mock Write-Host
        Mock Write-Debug

        $r = New-Runlist -Names '' -Debug
        $r | Should Be $null
    }

    It 'Returns a list of runbook plays when -ListAvailable is passed in.' {
        Mock Write-Host
        Mock Write-Debug

        $r = New-Runlist -ListAvailable
        $r | Should Be $null
    }
}
