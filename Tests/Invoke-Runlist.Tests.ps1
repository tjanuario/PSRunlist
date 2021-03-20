
Describe 'Invoke-Runlist' {
    $mockRunbookPath = Join-Path $TestDrive -ChildPath MockRunbook
    New-Item -Path $mockRunbookPath -ItemType Directory 
    New-Item -Path "$mockRunbookPath\attributes" -ItemType Directory 
    New-Item -Path "$mockRunbookPath\attributes\foobar.json" -ItemType File 
    New-Item -Path "$mockRunbookPath\parameters" -ItemType Directory 
    New-Item -Path "$mockRunbookPath\runbook" -ItemType Directory  
    New-Item -Path "$mockRunbookPath\parameters\childDirectory" -ItemType Directory 
    New-Item -Path "$mockRunbookPath\parameters\childDirectory\foobar.json" -ItemType File 

    $mockRunbookJsonPath = "$mockRunbookpath\runbook.json"

    Context 'When missing the file pointed to in runlist' {
        Set-Content $mockRunbookJsonPath -Value @'
                {
                    "runbooks": {
                        "default": [
                            "MockRunbook::missingFile"
                        ]
                    }
                }
'@ 
        
        
        
        It "Should thow an exception" {
            Mock Write-Debug
            
            $r = New-Runbook -Path $mockRunbookJsonPath
            $runlist = [PSCustomObject]@{
                "runbooks" = @{$r.Name = $r};
                "runbookArray" = @($r.Name);
                "runlist" = @("MockRunbook");
                "attributes" = [PSCustomObject]@{}
            }
    
            {
                $runlist | Invoke-Runlist -Debug
            } | Should Throw 
        }
    }
}
