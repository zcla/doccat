param (
    [Parameter(Mandatory=$true)][Object]$config
)

Set-Location $PSScriptRoot

foreach ($download in $config.download) {
    Write-Host -ForegroundColor Cyan "  $($download.sigla)" -NoNewline
    & ".\$($download.sigla).ps1" $config $($download.sigla)
}
