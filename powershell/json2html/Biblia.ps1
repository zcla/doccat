param(
	[Parameter(Mandatory)][string]$id
)

. ..\utils\Encoding.ps1

Set-Location $PSScriptRoot
$prjPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName

Write-Host "Inicializando" -ForegroundColor Cyan
..\utils\Import-ModulePowerHTML.ps1

Write-Host "Biblia" -ForegroundColor Cyan

$config = Convert-UnicodeC1ControlCharacters_to_HtmlEntities (Get-Content -Path "$prjPath\config\config.json") | ConvertFrom-Json -AsHashtable

$fileName = "$prjPath\temp\json\$id.json"
$biblia = Convert-UnicodeC1ControlCharacters_to_HtmlEntities (Get-Content $fileName) | ConvertFrom-Json -AsHashtable
$idBiblia = $id.replace('Biblia_', '')

$fileName = "$prjPath\html\biblia"
ForEach ($objLivro In $biblia.ordem) {
	$sigla = $objLivro.sigla
	Write-Host "  $sigla" -ForegroundColor Cyan -NoNewline
	$livro = $biblia.livros.$sigla
	$configLivro = $config.biblia.livro | Where-Object { $_.sigla -eq $sigla }
	$htmlLivro = @"
<div id="$sigla">
	<p class="nome">$($configLivro.nomeLongo)</p>
"@
	If ($objLivro.capitulos.Count -gt 1) {
		$htmlLivro += @"

	<p class="capitulos">
"@
	}
	ForEach ($objCapitulo In $objLivro.capitulos) {
		$numCapitulo = $objCapitulo.capitulo
		If ($numCapitulo -match '^#') {
			Continue
		}
		If ($numCapitulo -ne '-') {
			$htmlLivro += @"

		<a href="?pagina=biblia&amp;livro=$sigla&amp;capitulo=$numCapitulo">$numCapitulo</a>
"@
		}
		Write-Host " $numCapitulo" -ForegroundColor Cyan -NoNewline
		$capitulo = $livro.capitulos.$numCapitulo
		$htmlCapitulo = @"
<div>
"@
		If ($numCapitulo -ne '-') {
			$htmlCapitulo += @"

	<span class="capitulo">$numCapitulo</span>
"@

		}
		ForEach ($numVersiculo In $objCapitulo.versiculos) {
			if ($capitulo.versiculos.$numVersiculo.titulos) {
				foreach ($titulo in $capitulo.versiculos.$numVersiculo.titulos) {
					If ($numCapitulo -eq '-') {
						$htmlLivro += @"

	<span class="titulo">$titulo</span>
"@
					} Else {
						$htmlCapitulo += @"

	<span class="titulo">$titulo</span>
"@
					}

				}
			}
			If ($numCapitulo -eq '-') {
				$htmlLivro += @"

	<span class="versiculo"><sup>$numVersiculo</sup> $($capitulo.versiculos.$numVersiculo.texto)</span>
"@
			} Else {
				$htmlCapitulo += @"

	<span class="versiculo"><sup>$numVersiculo</sup> $($capitulo.versiculos.$numVersiculo.texto)</span>
"@
			}
		}
		$htmlCapitulo += @"

</div>
"@
		if ($capitulo.fonte) {
			$textoLink = $capitulo.fonte -replace "^https?:\/\/(www\.)?([^\/]+)\/?.*$", "`$2"
			$htmlCapitulo += @"

<div class="alert alert-info">
	<b>Fonte:</b> <a href="$($capitulo.fonte)" target="_blank">$textoLink<img class="align-text-bottom" src="img/linkExterno.svg"></a>.
</div>
"@

		}
		$fileName = "$prjPath\html\biblia\$idBiblia\$sigla\$numCapitulo\index.html"
		If ($numCapitulo -ne '-') {
			$htmlCapitulo | Out-File (New-Item $fileName -Force)
		}
	}
	If ($objLivro.capitulos.Count -gt 1) {
		$htmlLivro += @"

	</p>
"@
	}
	$htmlLivro += @"

</div>
"@
	$fileName = "$prjPath\html\biblia\$idBiblia\$sigla\index.html"
	$htmlLivro | Out-File (New-Item $fileName -Force)
	Write-Host ""
}
