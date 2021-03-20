function Merge-HashTable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PSCustomObject]$base, # your original set
        
        [PSCustomObject]$extend, # the set you want to update/append to the original set

        [Parameter(Mandatory=$true)]
        [string]$attributeLevel,

        [Parameter(DontShow=$true)]
        [string]$internal = ''
    )

    if ($extend) {
        $propNames = $($extend | Get-Member -MemberType *Property).Name
        foreach ($propName in $propNames) {
            if ($base.PSObject.Properties.Match($propName).Count) {
                if ($null -ne $base.$propName -and $base.$propName.GetType().Name -eq 'PSCustomObject')
                {
                    $base.$propName = Merge-HashTable -base $base.$propName -extend $extend.$propName $attributeLevel -internal "$internal.$propName"
                }
                else
                {
                    if ($attributeLevel -eq 'default_attributes') {
                        $attributeName = '$attributes' + "$internal.$propName"
                        Write-Warning "default attribute already exists for attribute $attributeName"
                    }
                    $base.$propName = $extend.$propName
                }
            }
            else
            {
                if ($attributeLevel -in 'override_attributes') {
                    $attributeName = $attributeName = '$attributes' + "$internal.$propName"
                    Write-Warning "overriding attribute $attributeName that has not been set by a default attribute"
                }

                $base | Add-Member -MemberType NoteProperty -Name $propName -Value $extend.$propName
            }
        }
    }
    return $base
}