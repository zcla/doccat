Set-Location $PSScriptRoot
$prjPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$id = (Get-Item $PSCommandPath).Name -replace '\.ps1', ''

Write-Host "Inicializando" -ForegroundColor Cyan
..\utils\Import-ModulePowerHTML.ps1

$config = Get-Content -Path "$prjPath\config\config.json" | ConvertFrom-Json -AsHashtable

Write-Host "Biblia" -ForegroundColor Cyan

$dados = Get-Content -Path "$prjPath\temp\download\$id.json" | ConvertFrom-Json -AsHashtable

$fileName = "$prjPath\temp\json\$id.json"
Write-Host "  JSON" -ForegroundColor Cyan -NoNewline
If (Test-Path $fileName) {
	Write-Host " ok" -ForegroundColor Green
} Else {
	Write-Host " gerando..." -ForegroundColor Yellow
	
	$result = [ordered]@{
		livros = [ordered]@{}
	}
	ForEach ($keyLivro In $dados.livros.Keys) {
		$nome = $keyLivro.Replace('1', 'I ').Replace('2', 'II ').Replace('3', 'III ')
		$sigla = $config.biblia.livro | Where-Object { $_.nomeCurto -eq $nome }
		if ($sigla) {
			$sigla = $sigla.sigla
		} else {
			$sigla = $config.download.$id.'mapa-livro'.$keyLivro
		}
		Write-Host "    $sigla ($keyLivro)" -ForegroundColor Cyan -NoNewline
		$result.livros.$sigla = [ordered]@{
			capitulos = [ordered]@{}
			fonte = $dados.livros.$keyLivro.fonte
		}
		foreach ($texto in $dados.livros.$keyLivro.texto) {
			$htmlDom = ConvertFrom-Html -Content $texto.texto
			$nodes = $htmlDom.SelectSingleNode("//body").ChildNodes
			$titulos = @()
			$numCapitulo = ''
			$numVersiculo = ''
			foreach ($node1 in $nodes) {
				if ($node1.Name -eq 'a') {
					foreach ($node2 in $node1.ChildNodes) {
						if ($node2.Name -eq 'h2') {
							# É um título
							$titulos += $node2.InnerText.Trim()
							continue
						}
						if ($node2.Name -eq 'b') {
							$texto = $node2.InnerText
							if (($sigla -eq 'Eclo') -and ($numVersiculo -eq '(li.')) {
								# Trata o "prólogo do tradutor grego" do Eclesiástico
								if ($result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo.texto -eq '(li.') {
									$result.livros.$sigla.capitulos.$numCapitulo.versiculos.Remove($numVersiculo)
									$restoNumVersiculo = $texto.Split(' ')[0]
									$texto = $texto.Substring($restoNumVersiculo.Length + 1)
									$numVersiculo = "$numVersiculo $restoNumVersiculo"
									$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo = @{
										texto = @()
									}
								} else {
									throw '?!?!'
								}
							}
							if ($texto -match "^\d+$") {
								# É um número de capítulo
								$numCapitulo = $texto
								$numVersiculo = ''
								Write-Host " $numCapitulo" -ForegroundColor Cyan -NoNewline
								$result.livros.$sigla.capitulos.$numCapitulo = [ordered]@{
									versiculos = [ordered]@{}
								}
							} else {
								# É só um texto em negrito
								if (($sigla -eq 'Eclo') -and ($numVersiculo.StartsWith('(li. '))) {
									$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo.texto += "<b>$texto</b>"
								} else {
									$texto = $node2.InnerHtml
									if (("$sigla $numCapitulo $numVersiculo" -eq 'Os 14 1') -and ($texto.StartsWith('1'))) {
										# A numeração alternativa aparece antes da "oficial"
										$texto = $texto.Substring(1).Trim()
										$numVersiculo = '1'
										$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo = @{
											texto = @()
										}
									}
		
									$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo.texto += "<b>$texto</b>"
								}
							}
							continue
						}
						if ($node2.Name -eq 'br') {
							# É uma quebra de linha
							if ($numCapitulo -and $numVersiculo) {
								$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo.texto += '<br>'
							}
						}
						if ($node2.Name -eq 'i') {
							$texto = $node2.InnerHtml
							# É só um texto em itálico
							if ("$sigla $numCapitulo $numVersiculo" -eq 'Br 6 ') {
								# Capítulo com texto antes do primeiro versículo
								$numVersiculo = '-'
								$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo = @{
									texto = @()
								}
							}
							if ("$sigla $numCapitulo $numVersiculo" -eq 'Os 14 ') {
								# A numeração alternativa aparece antes da "oficial"
								$numVersiculo = '1'
								$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo = @{
									texto = @()
								}
							}
							if ("$sigla $numCapitulo $numVersiculo" -in @('Sl 77 ', 'Sl 85 ', 'Sl 122 ', 'Sl 127 ')) {
								# O versículo não está destacado
								if ($texto.Substring(0, 1) -eq '1') {
									$texto = $texto.Substring(1)
									$numVersiculo = '1'
									$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo = @{
										texto = @()
									}
								} else {
									throw '?!?!'
								}
							}
							$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo.texto += "<i>$texto</i>"
						}
						if ($node2.Name -eq 'sup') {
							# É um número de versículo
							$numVersiculo = $node2.InnerText
							$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo = @{
								texto = @()
							}
							if ($titulos.Count -gt 0) {
								# Há títulos a adicionar
								foreach ($titulo in $titulos) {
									if (-not $result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo.titulos) {
										$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo.titulos = @()
									}
									$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo.titulos += @($titulo)
								}
								$titulos = @()
							}
							continue
						}
						if ($node2.Name -eq '#text') {
							# É um trecho do texto
							$texto = $node2.InnerHtml.Trim()
							if ($texto) {
								if (-not $numCapitulo) {
									if ($sigla -eq 'Eclo') {
										# Trata o "prólogo do tradutor grego" do Eclesiástico
										$numCapitulo = 'Prólogo'
										Write-Host " $numCapitulo" -ForegroundColor Cyan -NoNewline
										$result.livros.$sigla.capitulos.$numCapitulo = [ordered]@{
											versiculos = [ordered]@{}
										}
									} else {
										throw '?!?!'
									}
								}
								if (($sigla -eq 'Eclo') -and ($numCapitulo -eq 'Prólogo') -and ($texto -eq '(li.')) {
									# Trata o "prólogo do tradutor grego" do Eclesiástico
									$numVersiculo = $texto
									$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo = @{
										texto = @()
									}
								}
								if (-not $numVersiculo) {
									if ($sigla -eq 'Sl') {
										# Nos salmos aparece antes do primeiro versículo a numeração da Vulgata
										$result.livros.$sigla.capitulos.$numCapitulo.numeracaoVulgata = $texto
										continue
									} elseif ("$sigla $numCapitulo $numVersiculo" -eq 'Is 53 ') {
										# Tem texto antes do versículo que deveria estar depois
										$numVersiculo = '1'
										$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo = @{
											texto = @()
										}
									} elseif ("$sigla $numCapitulo $numVersiculo" -in ('1Rs 16 ', '1Rs 20 ')) {
										# O versículo não está destacado
										if ($texto.Substring(0, 1) -eq '1') {
											$texto = $texto.Substring(1)
											$numVersiculo = '1'
											$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo = @{
												texto = @()
											}
										} else {
											throw '?!?!'
										}
									} else {
										throw '?!?!'
									}
								}
								if (-not $sigla) {
									throw '?!?!'
								}
								$result.livros.$sigla.capitulos.$numCapitulo.versiculos.$numVersiculo.texto += $texto
							}
							continue
						}
					}
				}
			}
		}
		Write-Host ""
	}

	$temp = $result
	$result = [ordered]@{
		livros = [ordered]@{}
		ordem = @()
	}
	ForEach ($livro In $config.biblia.livro) {
		$sigla = "$($livro.sigla)"
		$result.livros.$sigla = $temp.livros.$sigla
		$capitulos = @()
		ForEach ($capitulo In ($result.livros.$sigla.capitulos.Keys | Where-Object { $_ -notmatch '#' })) {
			$versiculos = @()
			ForEach ($versiculo In ($result.livros.$sigla.capitulos.$capitulo.versiculos.Keys | Where-Object { $_ -notmatch '#' })) {
				$versiculos += $versiculo
				# TODO Remover <br>s no final
				# TODO Tratamento dos caracteres "alienígenas" (encoding?)
			}
			$capitulos += @{
				capitulo = $capitulo
				versiculos = $versiculos
			}
		}
		$result.ordem += @{
			sigla = $sigla
			capitulos = $capitulos
		}
	}

	Write-Host "    Gravando" -ForegroundColor Cyan -NoNewline
	$result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
	Write-Host " ok" -ForegroundColor Green
}
