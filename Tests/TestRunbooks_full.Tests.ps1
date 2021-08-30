$pwd = Get-Location


Describe 'Full integration test' {

    Function ConvertFrom-Yaml {
        # This is a function from powershell-yaml.  We don't know that it is loaded since its optional.
        # We don't actually need it to do anything because we are going to mock it.
        return ('{"override_attributes": {"attribute": { "name": {"value": "unspecified"}}}}' | ConvertFrom-json )
    }

    Mock Invoke-Expression {}
    Mock Write-Host -ParameterFilter {$foregroundColor -eq 'green'}
    Mock Get-PowershellYaml { $true }
    Mock ConvertFrom-Yaml {
        return ('{"override_attributes": {"attribute": { "name": {"value": "unspecified"}}}}' | ConvertFrom-json )
    }

    Context 'For a runbook name that is not valid in the current path' {
        Mock Write-Host -ParameterFilter {$foregroundColor -eq 'yellow'}

        Set-Location $PSScriptRoot\..\TestRunbooks
        $r = New-Runlist -Names NotAValidRunbook
        Set-Location $pwd

        It 'returns a list of valid runbookplays' {
            Assert-MockCalled Write-Host -Times 4
        }

        #It 'returns a $null' {
        #    $r | Should Be $null
        #}
    }

    Context 'For the root runbook TestRunbooks' {
        Set-Location $PSScriptRoot\..\TestRunbooks
        $r = New-Runlist -Names TestRunbooks, autorun -autorunparam onlyvalidparameter -rootparam myparam
        Set-Location $pwd

        It 'runbooks hashtable contains 3 runbooks' {
            $r.runbooks.Count | Should Be 3
            $r.runbooks.TestRunbooks | Should Not BeNullOrEmpty
            $r.runbooks.runbook1_dependency | Should Not BeNullOrEmpty
            $r.runbooks.autorun | Should Not BeNullOrEmpty
        }

        It 'runbookarray array contains 3 runbooks' {
            $r.runbookArray[0] | Should Be 'runbook1_dependency'
            $r.runbookArray[1] | Should Be 'autorun'
            $r.runbookArray[2] | Should Be 'TestRunbooks'
        }

        It 'runlist array contains 2 recipe ' {
            $r.runlist.Count | Should Be 2
            $r.runlist -contains 'TestRunbooks::default' | Should Be $true
        }

        It 'contains 7 root attributes' {
            $attributes = $r.attributes | Convert-PSObjectToHashtable
            $attributes.Count | Should Be 7
        }

        It 'should execute 4 recipes' {
             $r | Invoke-Runlist
             Assert-MockCalled Invoke-Expression -Times 4
        }

        It 'allows -AdditionalConfig (json) to override attributes' {
            $adtlConfig = @'
            {
                "override_attributes": {
                    "testrunbooks": {
                        "root_attribute": "override based on additional config json"
                    }
                }
            }
'@
            $r = New-Runlist -Names TestRunbooks -autorunparam onlyvalidparameter -rootparam default -AdditionalConfig $adtlConfig
            $r.attributes.testrunbooks.root_attribute | Should Be 'override based on additional config json'
        }

        It 'allows -AdditionalConfig (file) to override attributes' {
            $adtlConfig = "TestDrive:\config.json"
            Set-Content $adtlConfig -Value @'
            {
                "override_attributes": {
                    "testrunbooks": {
                        "root_attribute": "override based on additional config file"
                    }
                }
            }
'@
            $r = New-Runlist -Names TestRunbooks -autorunparam onlyvalidparameter -rootparam default -AdditionalConfig $adtlConfig
            $r.attributes.testrunbooks.root_attribute | Should Be 'override based on additional config file'
        }
    }

    Context 'For the runbook runbook1 when rootparm = override and paramTwo = override' {
        Set-Location $PSScriptRoot\..\TestRunbooks
        $r = New-Runlist -Names runbook1 -autorunparam onlyvalidparameter -rootparam override -paramTwo override

        It 'attribute.TestRunbooks.root_attribute value should be override' {
          $r.attributes.TestRunbooks.root_attribute | Should Be 'override2'
        }
    }

    Context 'For the runbook runbook1' {
        Set-Location $PSScriptRoot\..\TestRunbooks
        $r = New-Runlist -Names runbook1 -autorunparam onlyvalidparameter -rootparam foobar
        Set-Location $pwd

        It 'runbooks hashtable contains 4 runbooks' {
            $r.runbooks.Count | Should Be 4
            $r.runbooks.TestRunbooks | Should Not BeNullOrEmpty
            $r.runbooks.runbook1_dependency | Should Not BeNullOrEmpty
            $r.runbooks.autorun | Should Not BeNullOrEmpty
            $r.runbooks.runbook1 | Should Not BeNullOrEmpty
        }

        It 'runbookarray array contains 4 runbooks' {
            $r.runbookArray[0] | Should Be 'runbook1_dependency'
            $r.runbookArray[1] | Should Be 'autorun'
            $r.runbookArray[2] | Should Be 'TestRunbooks'
            $r.runbookArray[3] | Should Be 'runbook1'
        }

        It 'runlist array contains 1 recipe ' {
            $r.runlist.Count | Should Be 1
            $r.runlist -contains 'runbook1::default' | Should Be $true
        }

        It 'contains 8 root attributes' {
            $attributes = $r.attributes | Convert-PSObjectToHashtable
            $attributes.Count | Should Be 8
        }

        It 'should execute 4 recipes' {
             $r | Invoke-Runlist
             Assert-MockCalled Invoke-Expression -Times 4
        }
    }
}
