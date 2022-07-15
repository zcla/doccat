Clear-Host

$prjPath = ((Get-Item $MyInvocation.MyCommand.Path).Directory.Parent.FullName)

$config = Get-Content -Path "$prjPath\config\config.json" | ConvertFrom-Json

Write-Host "Biblia" -ForegroundColor Cyan
$id = 'Biblia_vatican.va_lt'
$fileName = "$prjPath\download\$id.json"

Write-Host "  Download" -ForegroundColor Cyan -NoNewline
If (Test-Path $fileName) {
    Write-Host " ok" -ForegroundColor Green
} Else {
    Write-Host " não" -ForegroundColor Yellow

    $result = [ordered]@{}
    ForEach ($url In $config.download.$id.urls) {

        Write-Host "    $url" -ForegroundColor Cyan -NoNewline
        $iwr = Invoke-WebRequest $url
        $urlsLivros = $iwr.Links | Where-Object { $_.href -match '^nova-vulgata_(v|n)t_' }
        Write-Host " $($urlsLivros.Length) livros" -ForegroundColor Green
        ForEach ($urlLivro In $urlsLivros) {

            $livro = $urlLivro.href -replace '^nova-vulgata_(v|n)t_(.*)_lt.html', '$2'
            Write-Host "      $livro" -ForegroundColor Cyan -NoNewline
            $iwrLivro = Invoke-WebRequest "$($url.substring(0, $url.LastIndexOf('/')))/$($urlLivro.href)"
            $result.$livro = "$($iwrLivro.Content)"
            Write-Host " $($result.$livro.Length) bytes" -ForegroundColor Green
        }
    }

    Write-Host "    Gravando" -ForegroundColor Cyan -NoNewline
    $result | ConvertTo-Json -Depth 100 | Out-File $fileName
    Write-Host " ok" -ForegroundColor Green
}

Write-Host "  Lendo" -ForegroundColor Cyan -NoNewline
$dados = Get-Content $fileName | ConvertFrom-Json -AsHashtable
Write-Host " $($dados.Keys.Count) livros" -ForegroundColor Green

Write-Host "  Gerando html" -ForegroundColor Cyan
