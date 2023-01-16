Set-Location $PSScriptRoot
$prjPath = (Get-Item $PSScriptRoot).Parent.FullName

. .\utils\Encoding.ps1

# Write-Host "Inicializando" -ForegroundColor Cyan
# ..\utils\Import-ModulePowerHTML.ps1

Write-Host "Biblia" -ForegroundColor Cyan
$config = Convert-UnicodeC1ControlCharacters_to_HtmlEntities (Get-Content -Path "$prjPath\config\config.json") | ConvertFrom-Json -AsHashtable

Write-Host "  Biblia_vatican_lt" -ForegroundColor Cyan
$fileName = "$prjPath\temp\json\Biblia_vatican_lt.json"
$biblia = Convert-UnicodeC1ControlCharacters_to_HtmlEntities (Get-Content $fileName) | ConvertFrom-Json -AsHashtable
Write-Host "  Biblia_combo" -ForegroundColor Cyan
$fileName = "$prjPath\temp\json\Biblia_combo.json"
$bibliaCombo = Convert-UnicodeC1ControlCharacters_to_HtmlEntities (Get-Content $fileName) | ConvertFrom-Json -AsHashtable

$htmlLivro = @"
<h1>Comparativo entre edições da Bíblia</h1>
<div id="biblias">
	<table class="table table-sm table-bordered table-hover">
		<thead>
			<tr>
				<th>Livro</th>
				<th>Capítulos</th>
"@
foreach ($versao in $config.download) {
    $htmlLivro += @"

				<th>$($versao.nome)</th>
"@
}
$htmlLivro += @"

			</tr>
		</thead>
		<tbody>
"@
$contLivro = 0
$contCapitulo = @{
    combo = 0
}
foreach ($versao in $config.download) {
    $contCapitulo[$versao.sigla] = 0
}
Write-Host "Livros" -ForegroundColor Cyan
foreach ($objLivro in $bibliaCombo.ordem) {
	$sigla = $objLivro.sigla
	Write-Host "  $sigla" -ForegroundColor Cyan
    $numCapitulos = $objLivro.capitulos.Count
    $htmlLivro += @"

			<tr>
				<th><a href="./?pagina=estudo&id=biblias&livro=$sigla">$sigla</th>
                <td class="text-end">$($numCapitulos)</td>
"@
    $htmlCapitulo = @"
<h1>Comparativo entre edições da Bíblia - $sigla</h1>
<div id="biblias">
	<table class="table table-sm table-bordered table-hover">
		<thead>
			<tr>
				<th>Capítulo</th>
				<th>Versículos</th>
"@
    foreach ($versao in $config.download) {
        $htmlCapitulo += @"

				<th>$($versao.nome)</th>
"@
    }
    $htmlCapitulo += @"

            </tr>
        </thead>
        <tbody>
"@
    foreach ($objCapitulo in $objLivro.capitulos) {
        $capitulo = $objCapitulo.capitulo
        Write-Host "    $capitulo" -ForegroundColor Cyan
        $numVersiculos = $objCapitulo.versiculos.Count
        $htmlCapitulo += @"

			<tr>
				<th class="text-end"><a href="./?pagina=estudo&id=biblias&livro=$sigla&capitulo=$capitulo">$capitulo</th>
                <td class="text-end">$($numVersiculos)</td>
"@
        foreach ($versao in $config.download) {
            $numVersiculosVersao = $bibliaCombo.livros.$sigla.capitulos.$capitulo.versoes[$versao.sigla].versiculos.Count
            $class = 'ok'
            if ($numVersiculosVersao -ne $numVersiculos) {
                $class = 'nok'
            }
            $htmlCapitulo += @"

				<td class="text-end $class">$numVersiculosVersao</td>
"@
            # $contCapitulo[$versao.sigla] += $numVersiculosVersao
        }
    $htmlCapitulo += @"

            </tr>
"@

    }
    $htmlCapitulo += @"
        </tbody>
	</table>
</div>
"@
    $fileName = "$prjPath\html\estudo\biblias\$sigla.html"
    $htmlCapitulo | Out-File (New-Item $fileName -Force)
    foreach ($versao in $config.download) {
        $numCapitulosVersao = ($bibliaCombo.livros.$sigla.capitulos | Where-Object { $_.values.Values.($versao.sigla) }).Count
        $class = 'ok'
        if ($numCapitulosVersao -ne $numCapitulos) {
            $class = 'nok'
        }
        $htmlLivro += @"

				<td class="text-end $class">$numCapitulosVersao</td>
"@
        $contCapitulo[$versao.sigla] += $numCapitulosVersao
    }
    $htmlLivro += @"

            </tr>
"@
    $contLivro++
    $contCapitulo.combo += $numCapitulos
}
$htmlLivro += @"

		</tbody>
		<tfoot>
			<tr>
				<th class="text-end">$contLivro</th>
				<th class="text-end">$($contCapitulo.combo.ToString('N0'))</th>
"@
foreach ($versao in $config.download) {
    $htmlLivro += @"

				<th class="text-end">$($contCapitulo[$versao.sigla].ToString('N0'))</th>
"@
}
$htmlLivro += @"

			</tr>
		</tfoot>
	</table>
</div>
"@
$fileName = "$prjPath\html\estudo\biblias.html"
$htmlLivro | Out-File (New-Item $fileName -Force)
