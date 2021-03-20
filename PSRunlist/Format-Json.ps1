function Format-Json {
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    $json
  ) 
  if ($json -isnot [string]) {
    $json = $json | ConvertTo-Json -Depth 100
  }

  $indent = 0;
  ($json -Split '\n' |
    % {
      if ($_ -match '[\}\]]' -and $indent -gt 0) {
        # This line contains  ] or }, decrement the indentation level
        $indent--
      }
      $line = ("`t" * $indent) + $_.TrimStart().Replace(':  ', ': ')
      if ($_ -match '[\{\[]') {
        # This line contains [ or {, increment the indentation level
        $indent++
      }
      $line
  }) -Join "`n"
}