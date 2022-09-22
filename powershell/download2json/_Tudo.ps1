Clear-Host

Write-Host "Biblia_vatican_lt" -ForegroundColor Magenta
.\Biblia_vatican_lt.ps1

Write-Host "Biblia_clerus_pt" -ForegroundColor Magenta
.\Biblia_clerus_pt.ps1

Write-Host "Biblia_combo" -ForegroundColor Magenta
.\Biblia_combo.ps1 @('Biblia_vatican_lt', 'Biblia_clerus_pt')

Write-Host "Biblia_combo_diferencas" -ForegroundColor Magenta
.\Biblia_combo_diferencas.ps1
