Describe 'Verify that Import-Attributes' {
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
}