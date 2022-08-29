Clear-Host

Write-Host "Download" -ForegroundColor Blue
.\download\Biblia_vatican_lt.ps1
Set-Location ..

Write-Host "Download -> JSON" -ForegroundColor Blue
.\html2json\Biblia_vatican_lt.ps1
Set-Location ..

Write-Host "JSON -> HTML" -ForegroundColor Blue
.\json2html\Biblia_vatican_lt.ps1
Set-Location ..

Write-Host "Catecismo" -ForegroundColor Blue
.\Build-JsonCatecismo

Write-Host "Documentos" -ForegroundColor Blue
.\Build-JsonDocumento
