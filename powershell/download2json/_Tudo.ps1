Clear-Host

Write-Host "Biblia_vatican_lt" -ForegroundColor Magenta
.\Biblia_vatican_lt.ps1

Write-Host "Biblia_clerus_pt" -ForegroundColor Magenta
.\Biblia_clerus_pt.ps1

.\Biblia_combo.ps1 @('Biblia_clerus_pt', 'Biblia_vatican_lt')
