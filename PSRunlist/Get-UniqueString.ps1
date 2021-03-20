Function Get-UniqueString {
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$String, 
        [int]$Length=13
    )

    # Lower case the string in order to make case-insensitive
    $hashArray = (new-object System.Security.Cryptography.SHA512Managed).ComputeHash($string.ToLower().ToCharArray())
    -join ($hashArray[1..$length] | ForEach-Object { [char]($_ % 26 + [byte][char]'a') })
}