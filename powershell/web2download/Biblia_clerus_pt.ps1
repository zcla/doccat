param (
    [Parameter(Mandatory=$true)][Object]$config
)

$fileName = "..\..\download\$($config.sigla).json"
if (Test-Path $fileName) {
	Write-Host -ForegroundColor Green " ok"
} else {
	Write-Host -ForegroundColor Yellow " fazendo..."

	$url = $config.url
	Write-Host -ForegroundColor Cyan "    $url" -NoNewline
	$dataHora = Get-Date
	$result = [ordered]@{
		livros = [ordered]@{}
		dataHora = $dataHora
	}
	$iwr = Invoke-WebRequest $url
	$html = $iwr.Content | ConvertFrom-Html
	$links = $html.DescendantNodes() | Where-Object { ($_.Name -eq 'a') -and (($_.Attributes | Where-Object { $_.Name -eq 'href' }).Count -gt 0) }
	Write-Host -ForegroundColor Green " $($links.Count) livros"
	foreach ($link in $links) {
		$livro = $link.InnerText
		Write-Host -ForegroundColor Cyan "      $livro"

		Write-Host -ForegroundColor Cyan "        Estrutura" -NoNewline
		$href = ($link.Attributes | Where-Object { $_.Name -eq 'href' }).Value
		$urlLivro = "$($url.substring(0, $url.LastIndexOf('/')))/$href"
		$iwrLivro = Invoke-WebRequest $urlLivro
		$result.livros.$livro = @{
			estrutura = "$($iwrLivro.Content)"
			fonte = $urlLivro
			texto = @()
		}
		Write-Host -ForegroundColor Green " $($result.livros.$livro.estrutura.Length) bytes"

		Write-Host -ForegroundColor Cyan "        Texto"
		$htmlLivro = $iwrLivro.Content | ConvertFrom-Html
		$linksLivro = $htmlLivro.DescendantNodes() | Where-Object { ($_.Name -eq 'a') -and (($_.Attributes | Where-Object { $_.Name -eq 'href' }).Count -gt 0) }
		$urlsTexto = @()
		foreach ($linkLivro in $linksLivro) {
			$hrefTexto = ($linkLivro.Attributes | Where-Object { $_.Name -eq 'href' }).Value
			if ($hrefTexto -match '#') {
				$hrefTexto = $hrefTexto.Split('#')[0]
				$urlTexto = "$($url.substring(0, $url.LastIndexOf('/')))/$hrefTexto"
				if ($urlsTexto -contains $urlTexto) {
					continue
				}

				Write-Host -ForegroundColor Cyan "          $hrefTexto" -NoNewline
				$iwrTexto = Invoke-WebRequest $urlTexto
				$result.livros.$livro.texto += @{
					texto = "$($iwrTexto.Content)"
					fonte = $urlTexto
				}
				Write-Host -ForegroundColor Green " $($iwrTexto.Content.Length) bytes"
				$urlsTexto += $urlTexto
			}
		}
	}

	Write-Host -ForegroundColor Cyan "    Gravando" -NoNewline
	$result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
	Write-Host -ForegroundColor Green " ok"
}
