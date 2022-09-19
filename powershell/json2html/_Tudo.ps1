Clear-Host

$biblias = @('Biblia_clerus_pt', 'Biblia_vatican_lt')

foreach ($biblia in $biblias) {
    Write-Host $biblia -ForegroundColor Magenta
    .\Biblia.ps1 $biblia
}

Write-Host "Biblia_combo" -ForegroundColor Magenta
.\Biblia_combo.ps1 $biblias
