$scriptPath = Get-Item ($MyInvocation.MyCommand.Path)
Set-Location $scriptPath.PSParentPath
$fileName = ".\$($scriptPath.Name.split('.')[0]).json"

Write-Host "Inicializando" -ForegroundColor Cyan -NoNewline
$config = Get-Content -Path .\config.json | ConvertFrom-Json -AsHashtable
$result = [ordered]@{
	livros = [ordered]@{}
	ordemLivros = @()
	dataHora = (Get-Date)
}
Write-Host " ok" -ForegroundColor Green

Write-Host "Download" -ForegroundColor Cyan -NoNewline
if (Test-Path $fileName) {
	Write-Host " já feito" -ForegroundColor Green
} else {
	Write-Host " fazendo..." -ForegroundColor Yellow
	foreach ($url in $config.urls) {
		Write-Host "  $url" -ForegroundColor Cyan -NoNewline
		$iwr = Invoke-WebRequest $url
		$urlsLivros = $iwr.Links | Where-Object { $_.href -match '^nova-vulgata_(v|n)t_' }
		Write-Host " $($urlsLivros.Count) livros" -ForegroundColor Green
		foreach ($urlLivro in $urlsLivros) {
			$livro = $urlLivro.href -replace '^nova-vulgata_(v|n)t_(.*)_lt.html', '$2'
			Write-Host "    $livro" -ForegroundColor Cyan -NoNewline
			$urlLivro = "$($url.substring(0, $url.LastIndexOf('/')))/$($urlLivro.href)"
			$iwrLivro = Invoke-WebRequest $urlLivro
			$result.livros.$livro = @{
				texto = "$($iwrLivro.Content)"
				fonte = $urlLivro
				dataHora = (Get-Date)
			}
			$result.ordemLivros += $config.'mapa-livro'.$livro
			Write-Host " $($result.livros.$livro.texto.Length) bytes" -ForegroundColor Green
		}
	}

	Write-Host "Gravando" -ForegroundColor Cyan -NoNewline
	$result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
	Write-Host " ok" -ForegroundColor Green
}

Write-Host "Fim" -ForegroundColor Cyan
