Export-ModuleMember -Function dotfiler

$Functions  = @( Get-ChildItem -Path $PSScriptRoot\Functions\*.ps1 -ErrorAction SilentlyContinue )
$Internal = @( Get-ChildItem -Path $PSScriptRoot\Internal\*.ps1 -ErrorAction SilentlyContinue )

Foreach($import in @($Functions + $Internal))
{
    Try
    {
        . $import.fullname
    }
    Catch
    {
        Write-Error -Message "Failed to import function $($import.fullname): $_"
    }
}

Export-ModuleMember -Cmdlet $Functions.Basename
