. ..\utils\Encoding.ps1

Set-Location $PSScriptRoot
$prjPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName

Write-Host "Inicializando" -ForegroundColor Cyan
..\utils\Import-ModulePowerHTML.ps1

Write-Host "Carregando" -ForegroundColor Cyan

$config = Convert-UnicodeC1ControlCharacters_to_HtmlEntities (Get-Content -Path "$prjPath\config\config.json") | ConvertFrom-Json -AsHashtable

$filename = "$prjPath\temp\json\Biblia_combo.json"
$biblia = Convert-UnicodeC1ControlCharacters_to_HtmlEntities (Get-Content $fileName) | ConvertFrom-Json -AsHashtable

Write-Host "Conferindo" -ForegroundColor Cyan
$result = [ordered]@{
	livros = [ordered]@{}
	ordem = @()
}
foreach ($ordemLivro In $biblia.ordem) {
	$sigla = $ordemLivro.sigla
	Write-Host "  $sigla" -ForegroundColor Cyan -NoNewline
	$livro = $biblia.livros.$sigla
	foreach ($ordemCapitulo in $ordemLivro.capitulos) {
		$numCapitulo = $ordemCapitulo.capitulo
		Write-Host " $numCapitulo" -ForegroundColor Cyan -NoNewline
		$capitulo = $livro.capitulos.$numCapitulo
		foreach ($versao in $config.download.Keys) {
			if (-not $capitulo.versoes.$versao) {
				Write-Host -ForegroundColor Red " $versao" -NoNewline
			}
			<#
			if (-not $result.livros.$sigla.capitulos.$numCapitulo) {
				$result.livros.$sigla.capitulos.$numCapitulo = [ordered]@{
					versoes = [ordered]@{}
				}
			}
			$result.livros.$sigla.capitulos.$numCapitulo.versoes.$versao = [ordered]@{
				fonte = $capitulo.fonte
				versiculos = [ordered]@{}
			}
			foreach ($numVersiculo in $ordemCapitulo.versiculos) {
				$versiculo = $capitulo.versiculos.$numVersiculo
				$result.livros.$sigla.capitulos.$numCapitulo.versoes.$versao.versiculos.$numVersiculo = [ordered]@{
					texto = $versiculo.texto
				}
				if ($versiculo.titulos) {
					$result.livros.$sigla.capitulos.$numCapitulo.versoes.$versao.versiculos.$numVersiculo.titulos = $versiculo.titulos
				}
			}
			#>
		}
	}
	Write-Host ""
}
