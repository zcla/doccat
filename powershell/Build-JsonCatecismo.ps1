# Lê os arquivos estáticos do Catecismo e monta um JSON com os dados necessários aos scripts JavaScript

$prjPath = ((Get-Item $MyInvocation.MyCommand.Path).Directory.Parent.FullName)

Clear-Host

Write-Host "Inicializando" -ForegroundColor Cyan
.\Import-PowerHTML.ps1

$pathCatecismo = "$prjPath\html\catecismo"

$path = "$pathCatecismo.html"
Write-Host "$path" -ForegroundColor Cyan
$html = ConvertFrom-Html -Path "$path"
$links = $html.SelectNodes('//a') | Where-Object { $_.OuterHtml -match 'href="\?pagina=catecismo&grupo=.+"' }

$grupos = @()
$links | ForEach-Object {
    $grupo = $_.Attributes['href'].value -replace '^.*&grupo=(.+)$', '$1'
    $grupos += $grupo
}

$estrutura = @()
$grupos | ForEach-Object {
    $html = ConvertFrom-Html -Path "$pathCatecismo\$_\index.html"
    $refs = $html.SelectNodes('//ref-cic')
    $grupo = @()
    $refs | ForEach-Object {
        $cic = $_.Attributes['name'].Value
        If (-not $cic) {
            $cic = $_.InnerText
        }
        $grupo += $cic
    }
    $estrutura += [ordered]@{
        grupo = $_
        cic = $grupo
    }
}
$estrutura | ConvertTo-Json -Depth 100 | Out-File "$prjPath\html\json\catecismo.json"
