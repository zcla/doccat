Set-Location $PSScriptRoot
$prjPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$id = (Get-Item $PSCommandPath).Name -replace '\.ps1', ''

Write-Host "Inicializando" -ForegroundColor Cyan
..\utils\Import-ModulePowerHTML.ps1

Write-Host "Biblia" -ForegroundColor Cyan

$config = Get-Content -Path "$prjPath\config\config.json" | ConvertFrom-Json -AsHashtable

$fileName = "$prjPath\temp\json\$id.json"
$biblia = Get-Content $fileName | ConvertFrom-Json -AsHashtable
$idBiblia = $id.replace('Biblia_', '')

$fileName = "$prjPath\html\biblia"
ForEach ($objLivro In $biblia.'#ordem') {
    $sigla = $objLivro.sigla
    Write-Host "  $sigla" -ForegroundColor Cyan -NoNewline
    $livro = $biblia.$sigla
    $configLivro = $config.biblia.livro | Where-Object { $_.sigla -eq $sigla }
    $htmlLivro = @"
<div id="$sigla">
	<p class="nome">$($configLivro.nomeLongo)</p>
	<p class="capitulos">
"@
    ForEach ($objCapitulo In $objLivro.capitulos) {
        $numCapitulo = $objCapitulo.capitulo
        If ($numCapitulo -match '^#') {
            Continue
        }
        # TODO Tratar livros com um capítulo só
        $htmlLivro += @"

        <a href="?pagina=biblia&amp;livro=$sigla&amp;capitulo=$numCapitulo">$numCapitulo</a>
"@
        Write-Host " $numCapitulo" -ForegroundColor Cyan -NoNewline
        $capitulo = $livro.$numCapitulo
        ForEach ($keyVersiculo In $capitulo.Keys) {

        }
    }
    $fonte = $livro.'#fonte'
    $htmlLivro += @"

    </p>
    <p class="alert alert-info">
	    <b>Fonte:</b> <a href="$fonte" target="_blank">Site do Vaticano<img class="align-text-bottom" src="img/linkExterno.png"></a>.
    </p>
</div>
"@
    $fileName = "$prjPath\html\biblia\$idBiblia\$sigla\index.html"
    $htmlLivro | Out-File (New-Item $fileName -Force)
    Write-Host ""
}
