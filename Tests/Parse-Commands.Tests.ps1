
Describe 'Parse-Commands' {
    BeforeEach {
        $base = @'
            {
                "a_valid_script": "{[DateTime]::MinValue | Get-Date -Format 'MM/dd/yy'}",
                "looks_like_script_but_isnt" : "_{[DateTime]::MinValue | Get-Date -Format 'MM/dd/yy'}",
                "looks_like_script_but_isnt2" : "{[DateTime]::MinValue | Get-Date -Format 'MM/dd/yy'}_",
                "Array": [
                    {
                    "a_valid_script": "{[DateTime]::MinValue | Get-Date -Format 'MM/dd/yy'}",
                    "looks_like_script_but_isnt" : "_{[DateTime]::MinValue | Get-Date -Format 'MM/dd/yy'}",
                    "looks_like_script_but_isnt2" : "{[DateTime]::MinValue | Get-Date -Format 'MM/dd/yy'}_"
                    }
                ]
            }
'@
        $parsed = $base | ConvertFrom-Json
        $parsed | Parse-Commands
    }

    It 'When attribute contains a script (wrapped by {}), execute script and replace value with results' {
        $parsed.a_valid_script | Should Be '01/01/01'
        $parsed.a_valid_script | Should BeOfType 'string'
        $parsed.Array[0].a_valid_script | Should Be '01/01/01'
        $parsed.Array[0].a_valid_script | Should BeOfType 'string'
    }

    It 'When attribute is not a script (does not start with {), it is left as is' {
        $parsed.looks_like_script_but_isnt | Should Be "_{[DateTime]::MinValue | Get-Date -Format 'MM/dd/yy'}"
        $parsed.Array[0].looks_like_script_but_isnt | Should Be "_{[DateTime]::MinValue | Get-Date -Format 'MM/dd/yy'}"
    }

    It 'When attribute is not a script (does not end with }), it is left as is' {
        $parsed.looks_like_script_but_isnt2 | Should Be "{[DateTime]::MinValue | Get-Date -Format 'MM/dd/yy'}_"
        $parsed.Array[0].looks_like_script_but_isnt2 | Should Be "{[DateTime]::MinValue | Get-Date -Format 'MM/dd/yy'}_"
    }    
}