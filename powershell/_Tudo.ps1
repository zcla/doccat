Clear-Host

Set-Location $PSScriptRoot

Write-Host -ForegroundColor Cyan "Inicialização"
.\utils\Import-ModulePowerHTML.ps1

Write-Host -ForegroundColor Cyan "Configuração"
$config = Get-Content -Path "..\config\config.json" | ConvertFrom-Json

Write-Host -ForegroundColor Cyan "Download"
.\web2download\_Tudo.ps1 $config

throw "Revisão feita até aqui"

Write-Host "Download -> JSON" -ForegroundColor Blue
.\download2json\_Tudo.ps1

Write-Host "JSON -> HTML" -ForegroundColor Blue
.\json2html\Biblia_vatican_lt.ps1

Write-Host "Catecismo" -ForegroundColor Blue
.\Build-JsonCatecismo

Write-Host "Documentos" -ForegroundColor Blue
.\Build-JsonDocumento
