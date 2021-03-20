
Describe 'Format-Json' {
    It 'Outputs json correctly' {
        $object = [PSCustomObject]@{
            "this" = "that";
            "that" = "this";
            "foo" = "bar"
        }

        $json = $object | Format-Json
        $json.StartsWith('{') | Should Be $true
    }
}