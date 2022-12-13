. ..\utils\Encoding.ps1

Set-Location $PSScriptRoot
$prjPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName

Write-Host "Inicializando" -ForegroundColor Cyan
..\utils\Import-ModulePowerHTML.ps1

Write-Host "Carregando" -ForegroundColor Cyan

$config = Convert-UnicodeC1ControlCharacters_to_HtmlEntities (Get-Content -Path "$prjPath\config\config.json") | ConvertFrom-Json -AsHashtable

$fileName = "$prjPath\temp\json\Biblia_combo.json"
$biblia = Convert-UnicodeC1ControlCharacters_to_HtmlEntities (Get-Content $fileName) | ConvertFrom-Json -AsHashtable

Write-Host "Gerando HTML" -ForegroundColor Cyan

$fileName = "$prjPath\html\biblia"
foreach ($ordemLivro In $biblia.ordem) {
	$sigla = $ordemLivro.sigla
	Write-Host "  $sigla" -ForegroundColor Cyan -NoNewline
	$livro = $biblia.livros.$sigla
	$configLivro = $config.biblia.livro | Where-Object { $_.sigla -eq $sigla }
	$htmlLivro = @"
<div id="$sigla">
	<p class="nome">$($configLivro.nomeLongo)</p>
"@
	if ($ordemLivro.capitulos.Count -gt 1) {
		$htmlLivro += @"

	<p class="capitulos">
"@
	}
	foreach ($ordemCapitulo in $ordemLivro.capitulos) {
		$numCapitulo = $ordemCapitulo.capitulo
		If ($numCapitulo -ne '-') {
			$htmlLivro += @"

		<a href="javascript:Biblia.capitulo('$numCapitulo');">$numCapitulo</a>
"@
		}
		Write-Host " $numCapitulo" -ForegroundColor Cyan -NoNewline
		$capitulo = $livro.capitulos.$numCapitulo
		$htmlCapituloTabs = @"
<ul class="nav nav-tabs">
"@
		$htmlCapituloContent = @"
<div class="tab-content">
"@
		$active = " active"
		foreach ($keyVersao in ($config.download.sigla | Sort-Object -Descending)) {
			$versao = $capitulo.versoes.$keyVersao
			if ($versao) {
				$configVersao = $config.download | Where-Object { $_.sigla -eq $keyVersao }
				$htmlCapituloTabs += @"

    <li class="nav-item active">
        <a href="#biblia_capitulo_$($configVersao.sigla)" class="nav-link$active" data-bs-toggle="tab">$($configVersao.nome)</a>
    </li>
"@
				$htmlCapituloContent += @"

	<div id="biblia_capitulo_$($configVersao.sigla)" class="tab-pane show$active">
"@
				if ($numCapitulo -ne '-') {
					$htmlCapituloContent += @"

		<span class="capitulo">$numCapitulo</span>
"@
				}
				foreach ($numVersiculo in $ordemCapitulo.versiculos) {
					$versiculo = $versao.versiculos.$numVersiculo
					if ($versiculo.titulos) {
						foreach ($titulo in $versiculo.titulos) {
							$htmlCapituloContent += @"

		<span class="titulo">$titulo</span>
"@
						}
					}
					$htmlCapituloContent += @"

		<span class="versiculo"><sup>$numVersiculo</sup> $($versiculo.texto)</span>
"@
				}
				if ($versao.fonte) {
					$textoLink = $versao.fonte -replace "^https?:\/\/(www\.)?([^\/]+)\/?.*$", "`$2"
					$htmlCapituloContent += @"

		<div class="alert alert-info">
			<b>Fonte:</b> <a href="$($versao.fonte)" target="_blank">$textoLink<img class="align-text-bottom" src="img/linkExterno.svg"></a>.
		</div>
"@

				}
				$htmlCapituloContent += @"

	</div>
"@

				$active = ""
			} else {
				Write-Host "*" -ForegroundColor Red -NoNewline
			}
		}
		$htmlCapituloTabs += @"

</ul>
"@
		$htmlCapituloContent += @"

</div>
"@
		$fileName = "$prjPath\html\biblia\combo\$sigla\$numCapitulo\index.html"
		if ($numCapitulo -eq '-') {
			$htmlLivro += @"
$htmlCapituloTabs
$htmlCapituloContent
"@
		} else {
			@"
$htmlCapituloTabs
$htmlCapituloContent
"@ | Out-File (New-Item $fileName -Force)
		}
	}
	If ($ordemLivro.capitulos.Count -gt 1) {
		$htmlLivro += @"

	</p>
"@
	}
	$htmlLivro += @"

</div>
"@
	$fileName = "$prjPath\html\biblia\combo\$sigla\index.html"
	$htmlLivro | Out-File (New-Item $fileName -Force)
	Write-Host ""
}
