param (
    [Parameter(Mandatory=$true)][Object]$config
)

$fileName = "..\..\download\$($config.sigla).json"
if (Test-Path $fileName) {
	Write-Host -ForegroundColor Green " ok"
} else {
	Write-Host -ForegroundColor Yellow " fazendo..."

	$dataHora = Get-Date
	$result = [ordered]@{
		livros = [ordered]@{}
		dataHora = $dataHora
	}
	foreach ($url in $config.urls) {
		Write-Host -ForegroundColor Cyan "    $url" -NoNewline
		$dataHora = Get-Date
		$iwr = Invoke-WebRequest $url
		$urlsLivros = $iwr.Links | Where-Object { $_.href -match '^nova-vulgata_(v|n)t_' }
		Write-Host -ForegroundColor Green " $($urlsLivros.Count) livros"
		foreach ($urlLivro in $urlsLivros) {
			$livro = $urlLivro.href -replace '^nova-vulgata_(v|n)t_(.*)_lt.html', '$2'
			Write-Host -ForegroundColor Cyan "      $livro" -NoNewline
			$urlLivro = "$($url.substring(0, $url.LastIndexOf('/')))/$($urlLivro.href)"
			$iwrLivro = Invoke-WebRequest $urlLivro
			$result.livros.$livro = @{
				texto = "$($iwrLivro.Content)"
				fonte = $urlLivro
				dataHora = $dataHora
			}
			Write-Host -ForegroundColor Green " $($result.livros.$livro.texto.Length) bytes"
		}
	}

	Write-Host -ForegroundColor Cyan "    Gravando" -NoNewline
	$result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
	Write-Host -ForegroundColor Green " ok"
}
