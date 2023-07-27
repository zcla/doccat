$scriptPath = Get-Item ($MyInvocation.MyCommand.Path)
Set-Location $scriptPath.PSParentPath
$fileName = ".\$($scriptPath.Name.split('.')[0]).json"

Write-Host "Inicializando" -ForegroundColor Cyan -NoNewline
$dados = Get-Content -Path .\02fixdownload.json | ConvertFrom-Json -AsHashtable
..\..\..\utils\Import-ModulePowerHTML.ps1
Write-Host " ok" -ForegroundColor Green

Write-Host "Parsing" -ForegroundColor Cyan -NoNewline
if (Test-Path $fileName) {
	Write-Host " já feito" -ForegroundColor Green
} else {
	Write-Host " fazendo..." -ForegroundColor Yellow

	$result = [ordered]@{
		livros = [ordered]@{}
		ordemLivros = $dados.ordemLivros
	}
	foreach ($keyLivro in $dados.livros.Keys) {
		Write-Host "  $keyLivro" -ForegroundColor Cyan -NoNewline
		$result.livros.$keyLivro = [ordered]@{
			dataHora = $dados.livros.$keyLivro.dataHora
			fonte = $dados.livros.$keyLivro.fonte
			capitulos = [ordered]@{}
		}
		$htmlDom = ConvertFrom-Html -Content $dados.livros.$keyLivro.texto
		$ancoras = $htmlDom.SelectNodes("//a[@name]") | Where-Object { $_.InnerText }
		if ($ancoras.Count -eq 0) {
			$ancoras = $htmlDom.SelectNodes("//p") | Where-Object { $_.InnerHTML -match '\<br\>' }
		}
		Write-Host " $($ancoras.Count) capítulo(s)" -ForegroundColor Green -NoNewline
		foreach ($ancora in $ancoras) {
			$htmlCapitulo = $ancora
			while ($htmlCapitulo.Name -ne 'p') {
				$htmlCapitulo = $htmlCapitulo.ParentNode
			}
			$fase = 'inicio'
			$numCapitulo = ''
			$ultVersiculo = '*'
			foreach ($child in $htmlCapitulo.ChildNodes) {
				$texto = ($child.InnerText -replace "&nbsp;", " ").Trim()
				switch ($true) {
					(($fase -eq 'inicio') -and ($child.Name -eq '#text')) {
						if ($texto) {
							$fase = 'versiculos'
							$result.livros.$keyLivro.capitulos.$numCapitulo = [ordered]@{
								fonte = $dados.livros.$keyLivro.fonte
								versiculos = [ordered]@{}
							}
							Write-Host " $numCapitulo" -ForegroundColor Cyan -NoNewline
						} else {
							continue
						}
					}

					(($fase -eq 'inicio') -and ($child.Name -eq 'br')) {
						continue
					}

					(($fase -eq 'inicio') -and ($child.Name -in @('a', 'b', 'font'))) {
						if ($texto) {
							$numCapitulo = $texto.Trim()
							Write-Host " $numCapitulo" -ForegroundColor Cyan -NoNewline
							$result.livros.$keyLivro.capitulos.$numCapitulo = [ordered]@{
								fonte = $dados.livros.$keyLivro.fonte
								versiculos = [ordered]@{}
							}
							$fase = 'titulo'
						}
						continue
					}

					(($fase -eq 'titulo') -and ($child.Name -eq '#text')) {
						if ($texto) {
							$result.livros.$keyLivro.capitulos.$numCapitulo.vulgata = $texto
						}
						continue
					}

					(($fase -eq 'titulo') -and ($child.Name -eq 'br')) {
						$fase = 'versiculos'
						continue
					}

					(($fase -eq 'versiculos') -and ($child.Name -in @('#text', 'i'))) {
						if ($texto) {
							$versiculoExtra = ''
							if ($texto -match '\(\d+\)$') {
								$versiculoExtra = '(' + $texto.Split('(')[-1]
								$texto = $texto.Substring(0, $texto.Length - $versiculoExtra.Length).Trim()
							}
							if ($child.Name -eq 'i') {
								$texto = "<i>$texto</i>"
							}

							$numVersiculo = ''
							if ($texto -match '^\(?\d{1,3}[a-z]{0,2}\)?( |\\r\\n)') {
								$numVersiculo = $texto.Split(' ')[0]
								$texto = $texto.Substring($numVersiculo.Length).Trim()
							}
							if ($texto -match '^\d{1,3}$') {
								$numVersiculo = $texto
								$texto = ''
							}

							if ($numVersiculo) {
								if ($numVersiculo -match '^\(') {
									$result.livros.$keyLivro.capitulos.$numCapitulo.versiculos."$numVersiculo" = @{
										texto = ""
									}
									$numVersiculo = ''
									if ($texto -match '^\(?\d{1,3}[a-z]?\)? ') {
										$numVersiculo = $texto.Split(' ')[0]
										$texto = $texto.Substring($numVersiculo.Length).Trim()
										$result.livros.$keyLivro.capitulos.$numCapitulo.versiculos."$numVersiculo" = @{
											texto = $texto
										}
									}
								} else {
									$result.livros.$keyLivro.capitulos.$numCapitulo.versiculos."$numVersiculo" = @{
										texto = $texto
									}
								}    
								$ultVersiculo = $numVersiculo
							} else {
								if ($result.livros.$keyLivro.capitulos.$numCapitulo.versiculos."$ultVersiculo".texto) {
									$result.livros.$keyLivro.capitulos.$numCapitulo.versiculos."$ultVersiculo".texto += "`r`n"
								} else {
									$result.livros.$keyLivro.capitulos.$numCapitulo.versiculos."$ultVersiculo".texto = ""
								}
								$result.livros.$keyLivro.capitulos.$numCapitulo.versiculos."$ultVersiculo".texto += $texto
							}

							if ($versiculoExtra) {
								$result.livros.$keyLivro.capitulos.$numCapitulo.versiculos."$versiculoExtra" = @{
									texto = ""
								}
							}
						}
						continue
					}

					(($fase -eq 'versiculos') -and ($child.Name -eq 'br')) {
						continue
					}

					(($fase -eq 'versiculos') -and ($child.Name -eq 'font')) {
						continue
					}

					default {
						throw "Não sei tratar."
					}
				}
			}
		}
		Write-Host ""
	}

	Write-Host "Gravando" -ForegroundColor Cyan -NoNewline
	$result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
	Write-Host " ok" -ForegroundColor Green
}

Write-Host "Fim" -ForegroundColor Cyan
