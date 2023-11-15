$scriptPath = Get-Item ($MyInvocation.MyCommand.Path)
Set-Location $scriptPath.PSParentPath
$fileName = ".\$($scriptPath.Name.split('.')[0]).json"

Write-Host "Inicializando" -ForegroundColor Cyan -NoNewline
. ..\..\..\utils\JsonDoc.ps1
$dataHora = Get-Date
$config = Get-Content -Path .\config.json | ConvertFrom-Json -AsHashtable
$result = [JsonDoc_Estrutura]::new('biblia\vatican.va\lt', 'documento')
$result.setMetadata('dataHora', $dataHora)
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
			$id = $urlLivro.href -replace '^nova-vulgata_(v|n)t_(.*)_lt.html', '$2'
			Write-Host "    $id" -ForegroundColor Cyan -NoNewline
			$urlLivro = "$($url.substring(0, $url.LastIndexOf('/')))/$($urlLivro.href)"
			$dataHora = Get-Date
			$iwrLivro = Invoke-WebRequest $urlLivro
			$html = "$($iwrLivro.Content)"
			$livro = [JsonDoc_Estrutura]::new($id, 'livro')
			$livro.setMetadata('dataHora', $dataHora)
			$livro.setMetadata('fonte', $urlLivro)
			$livro.setMetadata('html', $html)
			$result.addConteudo($livro)
			Write-Host " $($html.Length) bytes" -ForegroundColor Green
		}
	}

	Write-Host "Gravando" -ForegroundColor Cyan -NoNewline
	$result.toJson() | Out-File (New-Item $fileName -Force)
	Write-Host " ok" -ForegroundColor Green
}

Write-Host "Fim" -ForegroundColor Cyan
