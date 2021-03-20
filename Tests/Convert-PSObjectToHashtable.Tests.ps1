
Describe 'Convert-PSObjectToHashtable' {
    
    # The PSCustomObject that we will convert back to a hashtable
    $object = [PSCustomObject] @{ "this" = "that" }

    It 'returns a hashtable when a PSCustomObject is passed in' {
        Convert-PSObjectToHashtable $object  | Should BeOfType Hashtable
    }

    It 'returns $null when $null is passed in' {
        Convert-PSObjectToHashtable $null | Should Be $null
    }

    It 'accepts object from pipeline' {
        $object  | Convert-PSObjectToHashtable | Should BeOfType Hashtable
    }
}