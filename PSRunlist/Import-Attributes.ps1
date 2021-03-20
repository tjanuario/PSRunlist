Function Import-Attributes {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$attributes,
        
        [Parameter(Mandatory=$true)]
        $attributeFile,
        
        [Parameter(Mandatory=$true)]
        [string]$attributeLevel
    )

    # If $attributeFile is a filepath then get the content, process a bit, and turn it into a json string
    if (Test-Path $attributeFile -ErrorAction SilentlyContinue) {
        $attributeFile = Get-Content -Path $attributeFile
    }

    # Process the json string into the base attributes
    $attributeFile = ($attributeFile | ConvertFrom-Json).$attributeLevel | ConvertTo-Json -Depth 100
    $extended = Expand-String -string $attributeFile | ConvertFrom-Json
    return Merge-HashTable -base $attributes -extend $extended -attributeLevel $attributeLevel
}