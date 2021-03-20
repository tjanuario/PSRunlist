Describe 'Get-UniqueString' {
    It 'returns 13 characters by default' {
        ('g' | Get-UniqueString).Length | Should Be 13
        ('dlw;sldkdldkdwowowlq;qkejlldldjs' | Get-UniqueString).Length | Should Be 13
    }
    It 'returns the correct number of requested characters' {
        (Get-UniqueString -String 'g' -Length 30).Length | Should Be 30
        (Get-UniqueString -String 'g' -Length 40).Length | Should Be 40
    }
    It 'is deterministic' {
        $val1 = Get-UniqueString -String 'deterministic' -Length 30
        $val2 = Get-UniqueString -String 'deterministic' -Length 30
        $val1 | Should Be $val2
    }
}