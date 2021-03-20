
Describe 'Verify that Expand-String' {
    It 'replaces variables in string to variable value' {
        $variable = 'myvalue'
        $variable2 = 'myvalue2'
        Expand-String -String '$variable = myvalue, $variable2 = myvalue2' | Should Be 'myvalue = myvalue, myvalue2 = myvalue2'
    }

    It 'throws an exception when there is no variable to replace a variable token' {
        {
            Expand-String -String '$variable = myvalue'
         } | Should Throw 'Cannot expand the following attribute: ''$variable = myvalue'''
    }
}