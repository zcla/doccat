$scriptPath = Get-Item ($MyInvocation.MyCommand.Path)
Set-Location $scriptPath.PSParentPath

$zeraTudo = $true
if ($zeraTudo) {
    Get-ChildItem -Path ".\*.json" | Where-Object -FilterScript { $_.Name -match '^\d{2}' } | Remove-Item
}

$passos = @(
    '01download',
    '02fixdownload',
    '03parse',
    '04fixjson',
    '05finaliza'
)

foreach ($passo in $passos) {
    Write-Host -ForegroundColor Magenta "----- $passo -----"
    & ".\$passo.ps1"
}

Write-Host -ForegroundColor Magenta "----- fim -----"
