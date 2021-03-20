Describe 'Function New-Runbook' {

    $mockRunbookPath = Join-Path $TestDrive -ChildPath MockRunbook
    New-Item -Path $mockRunbookPath -ItemType Directory 
    New-Item -Path "$mockRunbookPath/attributes" -ItemType Directory 
    New-Item -Path "$mockRunbookPath/attributes/foobar.json" -ItemType File 
    New-Item -Path "$mockRunbookPath/scripts" -ItemType Directory 
    New-Item -Path "$mockRunbookPath/scripts/myscript.ps1" -ItemType File
    New-Item -Path "$mockRunbookPath/parameters" -ItemType Directory 
    New-Item -Path "$mockRunbookPath/parameters/childDirectory" -ItemType Directory 
    New-Item -Path "$mockRunbookPath/parameters/childDirectory/foobar.json" -ItemType File 

    $mockRunbookJsonPath = "$mockRunbookpath/runbook.json"

    Context 'When all properties accounted for in runbook.json' {
        Set-Content $mockRunbookJsonPath -Value @'
                {
                    "parameters": [
                        {
                            "Name": "autorunparam"
                        }
                    ],
                    "dependencies": [
                        "runbook1_dependency"
                    ],
                    "runbooks": {
                        "default": [
                            "foo",
                            "bar"
                        ]
                    },
                    "autorun": [
                        "autorunbook"
                    ]
                }
'@ 

        BeforeEach {
            $r = New-Runbook -Path $mockRunbookJsonPath
        }

        It 'should contain a name property' {
            $r.name | Should Be 'mockrunbook'
        }

        It 'should contain a path property' {
            $r.path | Should Be $mockRunbookPath
        }

        It 'should contain a parameters property' {
            $r.parameters[0].Name | Should Be 'autorunparam'
        }

        It 'should contain a dependencies property' {
            $r.dependencies[0] | Should Be 'runbook1_dependency'
        }

        It 'should contain a runbooks property' {
            $r.runbooks.default[0] | Should Be 'foo'
            $r.runbooks.default[1] | Should Be 'bar'
        }

        It 'should contain an autorun property' {
            $r.autorun[0] | Should Be 'autorunbook'
        }

        It 'should contain an attributeFiles method' {
            $r.attributeFiles() -Replace '\\', '/' | Should Be ("$mockRunbookPath/attributes/foobar.json" -Replace '\\', '/')
        }

        It 'should contain an scripts property' {            
            $r.scripts -Replace '\\', '/' | Should Be ("$mockRunbookPath/scripts/myscript.ps1" -Replace '\\', '/')
        }

        It 'should contain a parameterFiles method' {
            $r.parameterFiles().childDirectory.foobar -Replace '\\', '/' | Should Be ("$mockRunbookPath/parameters/childDirectory/foobar.json" -Replace '\\', '/')
        }

        It 'should be able to find attribute file foobar.json through FileSystem property' { 
            $r.FileSystem.attributes.'foobar.json' -Replace '\\', '/' | Should Be ("$mockRunbookPath/attributes/foobar.json" -Replace '\\', '/')
        }

        It 'should return a parent property when parent folder has a runbook.json file' {
            $parent = Split-Path $TestDrive -Leaf
            Mock Test-Path -ParameterFilter {$Path -eq "$parent/runbook.json"} { return $true }
            Mock Test-Path -ParameterFilter {$Path -eq "$parent\runbook.json"} { return $true }
            $r.Parent | Should Be $parent
        }

        It 'should throw an exception on load for a runbook recipe that has the same name as a runbook defined in runbook.json' {
            New-Item -Path "$mockRunbookPath/runbook" -ItemType Directory 
            New-Item -Path "$mockRunbookPath/runbook/default.ps1" -ItemType File
             
            {
                New-Runbook -Path $mockRunbookJsonPath
            } | Should Throw
        }
    }

    Context 'When runbook.json is empty' {
        Set-Content $mockRunbookJsonPath -Value '{}'

        BeforeEach {
            $r = New-Runbook -Path $mockRunbookJsonPath
        }

        It 'should contain a name property' {
            $r.name.GetType() | Should Be 'string'
            $r.name | Should Be 'mockrunbook'
        }

        It 'should contain a path property' {
            $r.path.GetType() | Should Be 'string'
            $r.path | Should Be $mockRunbookPath
        }

        It 'should contain a parameters property' {
            $r.parameters.GetType() | Should Be 'System.Object[]'
            $r.parameters.Length | Should Be 0
        }

        It 'should contain a dependencies property' {
            $r.dependencies.GetType() | Should Be 'System.Object[]'
            $r.dependencies.Length | Should Be 0
        }

        It 'should contain a runbooks property' {
            $r.runbooks.GetType() | Should Be 'hashtable'
        }

        It 'should contain an autorun property' {
            $r.autorun.GetType() | Should Be 'System.Object[]'
            $r.autorun.Length | Should Be 0
        }
    }
}
