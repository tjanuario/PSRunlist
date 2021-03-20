
Function Parse-Commands {
    param (
        [Parameter(ValueFromPipeline)]
        $InputObject
    )

    $propNames = ($InputObject | Get-Member -MemberType *Property).Name
    foreach ($propName in $propNames) {
        if ($null -ne $inputObject.$propName) {
            if ($inputObject.$propName.GetType().Name -eq 'PSCustomObject') {
                Parse-Commands $inputObject.$propName 
            }
            elseif ($inputObject.$propName.GetType().Name -eq 'String') {
                $inputObject.$propName = Expand-String $inputObject.$propName
                if ($inputObject.$propName -match '^\{.*\}$') {
                    $inputObject.$propName = [ScriptBlock]::Create($InputObject.$propName).Invoke().Invoke().ToString()
                }
            }
            elseif ($inputObject.$propName.GetType().Name -eq 'Object[]') {
                $length = $inputObject.$propName.Length
                for ($i = 0; $i -lt $length; $i++) {
                    Parse-Commands $inputObject.$propName[$i]
                }
            }
        } 
        
    }
}