# Importa o PowerHTML, instalando, se necessário.

If (-not (Get-Module -ListAvailable PowerHTML)) {
    #####
    Write-Host "  Instalando PowerHTML" -ForegroundColor Cyan -NoNewline
    Install-Module PowerHTML -Force
    Write-Host " ok" -ForegroundColor Green
}
Import-Module PowerHTML
