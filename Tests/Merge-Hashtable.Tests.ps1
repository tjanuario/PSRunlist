
Describe 'Merge-Hashtable' {
    Context 'two attributes lists with identical attribute names' {
        Mock Write-Warning {}
        
        It 'merges a default_attribute with an override_attribute' {
            $merged = Merge-Hashtable -base $base -extend $extend -attributeLevel 'override_attributes'            
            $merged.first.second | Should Be 'first second value already has default'
        }

        It 'warns that a default_attribute is overridden by another default_attribute' {
            Merge-Hashtable -base $base -extend $extend -attributeLevel 'default_attributes'            
            Assert-MockCalled Write-Warning -Times 1
        }
        
        BeforeAll {
            $base= '{"first":{"second": "first second value"}}' | ConvertFrom-Json
            $extend = '{"first":{"second": "first second value already has default"}}' | ConvertFrom-Json
        }
    }

    Context 'when two attributes lists with non-matching attribute names' {
        Mock Write-Warning {}
        
         It 'warns when an override_attribute is added to attributes rather than updating an existing one' {
            Merge-Hashtable -base $base -extend $extend -attributeLevel 'override_attributes'            
            Assert-MockCalled Write-Warning -Times 1
        }

        It 'merges a default_attribute with a different default_attribute' {
            $merged = Merge-Hashtable -base $base -extend $extend -attributeLevel 'default_attributes'            
            $merged.first.second | Should Be 'first second value'
            $merged.first.third | Should Be 'first third value'
        }
        
        BeforeAll {
            $base= '{"first":{"second": "first second value"}}' | ConvertFrom-Json
            $extend = '{"first":{"third": "first third value"}}' | ConvertFrom-Json
        }
    }

    Context 'includes full name of attribute in warnings' {
        It 'when a default_attribute is overridden by another default_attribute and several levels are present' {
            Merge-Hashtable -base $base -extend $base -attributeLevel 'default_attributes' -WarningAction SilentlyContinue -WarningVariable wv
            $wv = ($wv | Foreach-Object {$_.Message})
            $wv -contains 'default attribute already exists for attribute $attributes.first.second.third' | Should Be $true
            $wv -contains 'default attribute already exists for attribute $attributes.first.second.fourth' | Should Be $true
            $wv.Count | Should Be 2
        }

        It 'when an override_attribute is added to attributes rather than updating an existing one and several levels are present' {
            Merge-Hashtable -base $base -extend $extend -attributeLevel 'override_attributes' -WarningAction SilentlyContinue -WarningVariable wv
            $wv = ($wv | Foreach-Object {$_.Message})
            $wv -contains 'overriding attribute $attributes.first.second.fifth that has not been set by a default attribute' | Should Be $true
            $wv.Count | Should Be 1
        }

        BeforeAll {
            $base = [PSCustomObject]@{
                "first" = [PSCustomObject]@{
                    "second" = [PSCustomObject]@{
                        "third" = "third";
                        "fourth" = "fourth"
                    }
                }
            }
            $extend = [PSCustomObject]@{
                "first" = [PSCustomObject]@{
                    "second" = [PSCustomObject]@{
                        "third" = "third";
                        "fifth" = "fifth"
                    }
                }
            }
        }
    }
}
