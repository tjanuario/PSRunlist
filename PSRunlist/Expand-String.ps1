function Expand-String {
    param (
        [string]$string
    )

    Set-StrictMode -version 2.0
    $retValue = ""
    
    foreach ($line in $string.split("`n")) {
        try {
            $retValue += $ExecutionContext.InvokeCommand.ExpandString($line)
        }
        catch {
            $trimmed = $line.Trim() 
            throw "Cannot expand the following attribute: '$trimmed'"
        }
    }
    
    $retValue
}