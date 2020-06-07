function Merge-Tokens() {
  [CmdletBinding()]
  param (
    [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
    [AllowEmptyString()]
    [String] $template,

    [Parameter(Mandatory = $true)]
    [HashTable] $tokens
  ) 
  try {

    [regex]::Replace( $template, '{{ *(?<tokenName>[\w\.]+) *}}', {
        param($match)
        $value = Invoke-Expression "`$tokens.$($match.Groups['tokenName'].Value)"

        if($value) {
          return $value
        } else {
          return $match
        }
      })

  } catch {
    Write-Error $_
  }
}
