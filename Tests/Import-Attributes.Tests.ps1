Describe "Verify that Get-PowershellYaml" {
    It 'tests for loaded powershell-yaml module' {
        Function Get-Module { $true }

        Get-PowershellYaml | Should Be $true
    }

    It 'tests for unloaded powershell-yaml module' {
        Function Get-Module {
            param (
                $name,
                [switch] $listavailable
            )
            if ($listavailable) { return $true}
            else {return $false }
        }

        Function Import-Module {}

        Get-PowershellYaml | Should Be $true
    }

    It 'tests for no powershell-yaml module' {
        Function Get-Module { $false }

        Get-PowershellYaml | Should Be $false
    }
}

Describe 'Verify that Import-Attributes' {
    Function ConvertFrom-Yaml {
        # This is a function from powershell-yaml.  We don't know that it is loaded since its optional.
        # We don't actually need it to do anything because we are going to mock it.
        return ('{"override_attributes": {"attribute": { "name": {"value": "unspecified"}}}}' | ConvertFrom-json )
    }

    Mock Write-Warning {}

    BeforeEach {
        $attributes = '{}' | ConvertFrom-Json
    }

    It 'loads attribute level default_attributes only if the loaded attributes don''t exist.' {
        (Import-Attributes `
            -attributes $attributes `
            -attributeFile $PSScriptRoot\attributes.json `
            -attributeLevel 'default_attributes').attribute.name.value | Should Be "default_attributes"
    }

    It 'warns about default_attributes being overridden by another default_attribute.' {
        # Load the base attributes
        Import-Attributes `
            -attributes $attributes `
            -attributeFile $PSScriptRoot\attributes.json `
            -attributeLevel 'default_attributes'

        # Load the base attributes again on top of the same base attributes
        Import-Attributes `
            -attributes $attributes `
            -attributeFile $PSScriptRoot\attributes.json `
        -attributeLevel 'default_attributes'

        Assert-MockCalled Write-Warning -Times 1
    }

    It 'loads attribute level override_attributes only if the loaded attributes already exist.' {
        Import-Attributes `
            -attributes $attributes `
            -attributeFile $PSScriptRoot\attributes.json `
            -attributeLevel 'default_attributes'

        (Import-Attributes `
            -attributes $attributes `
            -attributeFile $PSScriptRoot\attributes.json `
            -attributeLevel 'override_attributes').attribute.name.value | Should Be "override_attributes"
    }

    It 'loads default_attributes attribute level for string values' {
        (Import-Attributes `
            -attributes $attributes `
            -attributeLevel 'default_attributes' `
            -attributeFile '{"default_attributes": {"attribute": { "name": {"value": "should load"}}}}').attribute.name.value | Should Be "should load"
    }

    It 'loads override_attributes to overwrite existing default_attributes' {
        # Load default values that will be overridden
        Import-Attributes `
            -attributes $attributes `
            -attributeFile $PSScriptRoot\attributes.json `
            -attributeLevel 'default_attributes'

        (Import-Attributes `
            -attributes $attributes `
            -attributeLevel 'override_attributes' `
            -attributeFile '{"override_attributes": {"attribute": { "name": {"value": "unspecified"}}}}').attribute.name.value | Should Be "unspecified"
    }

    It 'warns when an override_attribute adds a new attribute rather than updating an existing one.' {
        Import-Attributes `
            -attributes $attributes `
            -attributeLevel 'override_attributes' `
            -attributeFile '{"override_attributes": {"attribute": { "name": {"value": "unspecified"}}}}'

        Assert-MockCalled Write-Warning -Times 1
    }

    It 'throws exception when yaml attribute file is loaded with no powershell-yaml module installed.' {
        Mock Get-PowershellYaml { $false }

        $yaml = @"
  override_attributes:
    attribute:
      name:
        value: unspecified
"@
        {
            Import-Attributes `
                -attributes $attributes `
                -attributeLevel 'override_attributes' `
                -attributeFile $yaml
        } | Should Throw 'Error processing: Passed in attribute string'
    }

    It 'loads with (mocked) powershell-yaml module installed.' {
        Mock Get-PowershellYaml { $true }
        Mock ConvertFrom-Yaml {
            return ('{"override_attributes": {"attribute": { "name": {"value": "unspecified"}}}}' | ConvertFrom-json )
        }

        $yaml = @"
  override_attributes:
    attribute:
      name:
        value: unspecified
"@

        Import-Attributes `
            -attributes $attributes `
            -attributeLevel 'override_attributes' `
            -attributeFile $yaml

            Assert-MockCalled ConvertFrom-Yaml -Times 1
    }
}
