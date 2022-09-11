Set-Location $PSScriptRoot
$prjPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$id = (Get-Item $PSCommandPath).Name -replace '\.ps1', ''

Write-Host "Inicializando" -ForegroundColor Cyan
..\utils\Import-ModulePowerHTML.ps1

$config = Get-Content -Path "$prjPath\config\config.json" | ConvertFrom-Json

Write-Host "Biblia" -ForegroundColor Cyan

$fileName = "$prjPath\temp\download\$id.json"
Write-Host "  Download" -ForegroundColor Cyan -NoNewline
If (Test-Path $fileName) {
	Write-Host " ok" -ForegroundColor Green
} Else {
	Write-Host " fazendo..." -ForegroundColor Yellow

	$result = [ordered]@{
		livros = [ordered]@{}
	}
	ForEach ($url In $config.download.$id.urls) {
		Write-Host "    $url" -ForegroundColor Cyan -NoNewline
		$dataHora = Get-Date
		$iwr = Invoke-WebRequest $url
		$urlsLivros = $iwr.Links | Where-Object { $_.href -match '^nova-vulgata_(v|n)t_' }
		Write-Host " $($urlsLivros.Count) livros" -ForegroundColor Green
		ForEach ($urlLivro In $urlsLivros) {
			#####
			$livro = $urlLivro.href -replace '^nova-vulgata_(v|n)t_(.*)_lt.html', '$2'
			Write-Host "      $livro" -ForegroundColor Cyan -NoNewline
			$urlLivro = "$($url.substring(0, $url.LastIndexOf('/')))/$($urlLivro.href)"
			$iwrLivro = Invoke-WebRequest $urlLivro
			$result.livros.$livro = @{
				texto = "$($iwrLivro.Content)"
				fonte = $urlLivro
				dataHora = $dataHora
			}
			Write-Host " $($result.livros.$livro.texto.Length) bytes" -ForegroundColor Green
		}
	}

	Write-Host "    Gravando" -ForegroundColor Cyan -NoNewline
	$result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
	Write-Host " ok" -ForegroundColor Green
}
