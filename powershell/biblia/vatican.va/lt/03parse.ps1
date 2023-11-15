$scriptPath = Get-Item ($MyInvocation.MyCommand.Path)
Set-Location $scriptPath.PSParentPath
$fileName = ".\$($scriptPath.Name.split('.')[0]).json"

Write-Host "Inicializando" -ForegroundColor Cyan -NoNewline
. ..\..\..\utils\JsonDoc.ps1
$result = [JsonDoc_Elemento]::fromJson((Get-Content -Path .\02fixdownload.json))
..\..\..\utils\Import-ModulePowerHTML.ps1
Write-Host " ok" -ForegroundColor Green

Write-Host "Parsing" -ForegroundColor Cyan -NoNewline
if (Test-Path $fileName) {
	Write-Host " já feito" -ForegroundColor Green
} else {
	Write-Host " fazendo..." -ForegroundColor Yellow

	foreach ($livro in $result.getConteudo()) {
		Write-Host "  $($livro.id)" -ForegroundColor Cyan -NoNewline
		$htmlDom = ConvertFrom-Html -Content $livro.getMetadata('html')
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
			$numCapitulo = ''
			$ultVersiculo = $null
			$fase = 'inicio'
			foreach ($child in $htmlCapitulo.ChildNodes) {
				$texto = ($child.InnerText -replace "&nbsp;", " ").Trim()
				switch ($true) {
					(($fase -eq 'inicio') -and ($child.Name -eq '#text')) {
						if ($texto) {
							$fase = 'versiculos'
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
							$capitulo = [JsonDoc_Estrutura]::new($numCapitulo, 'capitulo')
							$livro.addConteudo($capitulo)
							$fase = 'titulo'
						}
						continue
					}

					(($fase -eq 'titulo') -and ($child.Name -eq '#text')) {
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
									$versiculo = [JsonDoc_Texto]::new($numVersiculo, 'versiculo')
									$capitulo.addConteudo($versiculo)
									$numVersiculo = ''
									if ($texto -match '^\(?\d{1,3}[a-z]?\)? ') {
										$numVersiculo = $texto.Split(' ')[0]
										$texto = $texto.Substring($numVersiculo.Length).Trim()
										$versiculo = [JsonDoc_Texto]::new($numVersiculo, 'versiculo')
										$versiculo.addConteudo('texto', $texto)
										$capitulo.addConteudo($versiculo)
									}
								} else {
									$versiculo = [JsonDoc_Texto]::new($numVersiculo, 'versiculo')
									$versiculo.addConteudo('texto', $texto)
									if ($numCapitulo) {
										$capitulo.addConteudo($versiculo)
									} else {
										$livro.addConteudo($versiculo)
									}
								}
								$ultVersiculo = $versiculo
							} else {
								$ultVersiculo.addConteudo('texto', $texto)
							}

							if ($versiculoExtra) {
								$versiculo = [JsonDoc_Texto]::new($versiculoExtra, 'versiculo')
								$capitulo.addConteudo($versiculo)
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
		$livro.removeMetadata('html')
		Write-Host ""
	}

	Write-Host "Gravando" -ForegroundColor Cyan -NoNewline
    $result.toJson() | Out-File (New-Item $fileName -Force)
	Write-Host " ok" -ForegroundColor Green
}

Write-Host "Fim" -ForegroundColor Cyan
