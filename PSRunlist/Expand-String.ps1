function Expand-String {
    param (
        [string]$string
    )

    Set-StrictMode -version 2.0
    $retValue = ""
    
    foreach ($line in $string.split("`n")) {
        try {
            $previous = ''
            while ($previous -ne $line) {
                $previous = $line
                $line = $ExecutionContext.InvokeCommand.ExpandString($line)
            }
            $retValue += $line
        }
        catch {
            $trimmed = $line.Trim() 
            throw "Cannot expand the following attribute: '$trimmed'"
        }
    }
    
    $retValue
}