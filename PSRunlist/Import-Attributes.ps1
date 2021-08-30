Function Get-PowershellYaml {
    if (!(Get-Module -Name powershell-yaml)) {
        if (Get-Module -Name powershell-yaml -ListAvailable) {
            Import-Module -Name powershell-yaml
            return $true
        }
        else {
            return $false
        }
    }
    else {
        return $true
    }
}

Function Import-Attributes {
    param (
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$attributes,

        [Parameter(Mandatory=$true)]
        $attributeFile,

        [Parameter(Mandatory=$true)]
        [string]$attributeLevel
    )

    $fileName = 'Passed in attribute string'
    # If $attributeFile is a filepath then get the content
    if (Test-Path $attributeFile -ErrorAction SilentlyContinue) {
        $fileName  = $attributeFile
        $attributeFile = Get-Content -Path $attributeFile
    }

    # Process the json string into the base attributes
    try {
        $attributeFile = ($attributeFile | ConvertFrom-Json).$attributeLevel | ConvertTo-Json -Depth 100
    }
    catch {
        if (!(Get-PowershellYaml)) {
            throw "Error processing: ${filename}"
        }
        $attributeFile = ($attributeFile | ConvertFrom-Yaml).$attributeLevel | ConvertTo-Json -Depth 100

    }
    $extended =  $attributeFile | ConvertFrom-Json
    return Merge-HashTable -base $attributes -extend $extended -attributeLevel $attributeLevel
}
