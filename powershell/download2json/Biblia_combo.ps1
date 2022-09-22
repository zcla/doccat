param(
	[Parameter(Mandatory)][string[]]$versoes
)

. ..\utils\Encoding.ps1

Set-Location $PSScriptRoot
$prjPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName

Write-Host "Inicializando" -ForegroundColor Cyan
..\utils\Import-ModulePowerHTML.ps1

Write-Host "Carregando" -ForegroundColor Cyan

$config = Convert-UnicodeC1ControlCharacters_to_HtmlEntities (Get-Content -Path "$prjPath\config\config.json") | ConvertFrom-Json -AsHashtable

$filename = @{}
$biblia = @{}
$idBiblia = @{}
foreach ($versao in $versoes) {
	Write-Host "  $versao" -ForegroundColor Cyan
	$fileName.$versao = "$prjPath\temp\json\$versao.json"
	$biblia.$versao = Convert-UnicodeC1ControlCharacters_to_HtmlEntities (Get-Content $fileName.$versao) | ConvertFrom-Json -AsHashtable
	$idBiblia.$versao = $versao.replace('Biblia_', '')
}

Write-Host "Unificando" -ForegroundColor Cyan
$result = [ordered]@{
	livros = [ordered]@{}
	ordem = @()
}
foreach ($configLivro In $config.biblia.livro) {
	$sigla = $configLivro.sigla
	Write-Host "  $sigla" -ForegroundColor Cyan -NoNewline
	foreach ($versao in $versoes) {
		$objLivro = $biblia.$versao.ordem | Where-Object { $_.sigla -eq $sigla }
		$livro = $biblia.$versao.livros.$sigla
		if (-not $result.livros.$sigla) {
			$result.livros.$sigla = [ordered]@{
				capitulos = [ordered]@{}
			}
		}
		foreach ($objCapitulo in $objLivro.capitulos) {
			$numCapitulo = $objCapitulo.capitulo
			Write-Host " $numCapitulo" -ForegroundColor Cyan -NoNewline
			$capitulo = $livro.capitulos.$numCapitulo
			if (-not $result.livros.$sigla.capitulos.$numCapitulo) {
				$result.livros.$sigla.capitulos.$numCapitulo = [ordered]@{
					versoes = [ordered]@{}
				}
			}
			$result.livros.$sigla.capitulos.$numCapitulo.versoes.$versao = [ordered]@{
				fonte = $capitulo.fonte
				versiculos = [ordered]@{}
			}
			foreach ($numVersiculo in $objCapitulo.versiculos) {
				$versiculo = $capitulo.versiculos.$numVersiculo
				$result.livros.$sigla.capitulos.$numCapitulo.versoes.$versao.versiculos.$numVersiculo = [ordered]@{
					texto = $versiculo.texto
				}
				if ($versiculo.titulos) {
					$result.livros.$sigla.capitulos.$numCapitulo.versoes.$versao.versiculos.$numVersiculo.titulos = $versiculo.titulos
				}
			}
		}
	}
	Write-Host ""
}

Write-Host "Ordenando" -ForegroundColor Cyan -NoNewline
$temp = $result
$result = [ordered]@{
	livros = [ordered]@{}
	ordem = @()
}
foreach ($livro in $config.biblia.livro) {
	$sigla = "$($livro.sigla)"
	$result.livros.$sigla = $temp.livros.$sigla
	$capitulos = @()
	foreach ($capitulo in $result.livros.$sigla.capitulos.Keys) {
		$versiculos = @()
		foreach ($versao in $result.livros.$sigla.capitulos.$capitulo.versoes.Keys) {
			foreach ($versiculo in ($result.livros.$sigla.capitulos.$capitulo.versoes.$versao.versiculos.Keys)) {
				if ($versiculos -notcontains $versiculo) {
					$versiculos += $versiculo
				}
			}
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
Write-Host " ok" -ForegroundColor Green

$fileName = "$prjPath\temp\json\Biblia_combo.json"
Write-Host "Gravando" -ForegroundColor Cyan -NoNewline
$result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
Write-Host " ok" -ForegroundColor Green
