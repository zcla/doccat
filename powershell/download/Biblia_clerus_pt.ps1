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
    
    $url = $config.download.$id.url
    Write-Host "    $url" -ForegroundColor Cyan -NoNewline
    $dataHora = Get-Date
    $result = [ordered]@{
		dataHora = $dataHora
	}
    $iwr = Invoke-WebRequest $url
    $html = $iwr.Content | ConvertFrom-Html
    $links = $html.DescendantNodes() | Where-Object { ($_.Name -eq 'a') -and (($_.Attributes | Where-Object { $_.Name -eq 'href' }).Count -gt 0) }
    Write-Host " $($links.Count) livros" -ForegroundColor Green
    ForEach ($link In $links) {
        #####
        $livro = $link.InnerText
        Write-Host "      $livro" -ForegroundColor Cyan
        Write-Host "        Estrutura" -ForegroundColor Cyan -NoNewline
        $href = ($link.Attributes | Where-Object { $_.Name -eq 'href' }).Value
        $urlLivro = "$($url.substring(0, $url.LastIndexOf('/')))/$href"
        $iwrLivro = Invoke-WebRequest $urlLivro
        $result.$livro = @{
			estrutura = "$($iwrLivro.Content)"
            fonteEstrutura = $urlLivro
			texto = @()
        }
		Write-Host " $($result.$livro.estrutura.Length) bytes" -ForegroundColor Green

		#####
        Write-Host "        Texto" -ForegroundColor Cyan
		$htmlLivro = $iwrLivro.Content | ConvertFrom-Html
		$linksLivro = $htmlLivro.DescendantNodes() | Where-Object { ($_.Name -eq 'a') -and (($_.Attributes | Where-Object { $_.Name -eq 'href' }).Count -gt 0) }
		$urlsTexto = @()
		ForEach ($linkLivro In $linksLivro) {
			$hrefTexto = ($linkLivro.Attributes | Where-Object { $_.Name -eq 'href' }).Value
			if ($hrefTexto -match '#') {
				$hrefTexto = $hrefTexto.Split('#')[0]
				$urlTexto = "$($url.substring(0, $url.LastIndexOf('/')))/$hrefTexto"
				if ($urlsTexto -contains $urlTexto) {
					continue
				}
				# Download & store
				Write-Host "          $hrefTexto" -ForegroundColor Cyan -NoNewline
				$iwrTexto = Invoke-WebRequest $urlTexto
				$result.$livro.texto += @{
					texto = "$($iwrTexto.Content)"
					fonteEstrutura = $urlTexto
				}
				Write-Host " $($iwrTexto.Content.Length) bytes" -ForegroundColor Green
				$urlsTexto += $urlTexto
			}
		}
    }

    Write-Host "    Gravando" -ForegroundColor Cyan -NoNewline
    $result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
    Write-Host " ok" -ForegroundColor Green
}
