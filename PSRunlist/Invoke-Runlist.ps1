function  Invoke-Runlist {
    [CmdletBinding()]
    param(
        [Parameter (
                Mandatory=$True,
                Position=0,
                ValueFromPipeline=$true,
                ValueFromPipelineByPropertyName=$true
            )
        ]
        [PSCustomObject]$runlist
    )
    If ($PSBoundParameters['Debug']) {
        $DebugPreference = 'Continue'
    }
    $ErrorActionPreference = 'Stop'
    $start = Get-Date

    "--------------------" | Write-Debug
    "Begin Invoke-Runlist" | Write-Debug
    "--------------------" | Write-Debug

    # While these don't appear to be used, they are internal to the $runlist object so are not available
    # to the recipes.  This makes them part of the scope that is running the runlists.   
    $attributes = $runlist.attributes
    $runbooks = $runlist.Runbooks

    $Script:processedRecipes = @{}
    $Script:executeList = @()

    $runlist.runbookArray | ForEach-Object {
        $runbook = $runlist.runbooks[$_]
        "Loading $($runbook.Name) scripts" | Write-Debug
        $runbook.scripts | ForEach-Object {
            "`t Loading $_" | Write-Debug
            . $_
        }
        $runbook.autorun | ForEach-Object {
            $runbookName, $recipeName = $_ -split '::'
            if (! $recipeName) { $recipeName = 'default' }
            Process-Recipe "$runbookName::$recipeName"
        }
        $runlist.runlist | ForEach-Object {
            $recipe = $_
            $runbookName, $recipeFileName = $recipe -split '::'
            if ($runbook.name -eq $runbookName) {
                Process-Recipe $recipe
            }
        }
    }

    "-----------------------" | Write-Debug
    "Begin runbook execution" | Write-Debug
    "-----------------------" | Write-Debug

    # Execute the recipes that have been processed and loaded
    $Script:executeList | ForEach-Object {
        $recipeFile = $_
        "Executing ($recipeFile)" | Write-Host -ForegroundColor Green
        $pwd = Get-Location
        #Set-StrictMode -version 2.0
        Invoke-Expression $recipeFile | Out-Null
        #Set-StrictMode -Off
        Set-Location $pwd
    }

    $finish = Get-Date
    [TimeSpan]$timespan = $finish.Subtract($start)
    "Runtime: $($timespan.Hours)h $($timespan.Minutes)m $($timespan.Seconds)s" | Write-Host
}


Function Process-Recipe {
    param (
        $recipeName
    )            
    $runbookName, $recipeFileName = $recipeName -split '::'
    if (!$recipeFileName) { $recipeFileName = 'default'}

    "Process recipe: $recipeName" | Write-Debug
    if (!$Script:processedRecipes.ContainsKey($recipeName)) {
        $Script:processedRecipes[$recipeName] = $null
        $runbook = $runbooks[$runbookName]            
        "`t Retrieved runbook: $($runbook.Name)" | Write-Debug
        $recipe = $runbook.runbooks[$recipeFileName]

        if ($recipe -is [Array]) {
            "`t $recipeName is an array of recipes.  Process each: $recipe" | Write-Debug
            $recipe | ForEach-Object {
                Process-Recipe $_
            }
        }
        else {
            $runbookFolder = Join-Path $runbook.Path -ChildPath runbook
            $recipeFile = Join-Path $runbookFolder -ChildPath "$recipeFileName.ps1"
            if (Test-Path $recipeFile) {
                "`t Adding recipe: $recipeName to execution list." | Write-Debug
                $Script:executeList += $recipeFile
            }
            else {
                "`t $recipeName should point to file $recipeFile, which does not exist." | Write-Error
            }
        }
    }
    else {
        "$`t $recipeName has already been processed. Skipping..." | Write-Debug
    }
}