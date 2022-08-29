# Lê os arquivos estáticos do Catecismo e monta um JSON com os dados necessários aos scripts JavaScript

$prjPath = ((Get-Item $MyInvocation.MyCommand.Path).Directory.Parent.FullName)

Write-Host "Inicializando" -ForegroundColor Cyan
.\utils\Import-ModulePowerHTML.ps1

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

$result = @()
$ultGrupo = $null
$grupos | ForEach-Object {
    If ($_ -eq $ultGrupo) {
        Return
    }
    $html = ConvertFrom-Html -Path "$pathCatecismo\$_\index.html"
    $refs = $html.SelectNodes('//ref-cic')
    $grupo = @()
    $refs | ForEach-Object {
        $cic = $_.Attributes['numero'].Value
        If (-not $cic) {
            $cic = $_.InnerText
        }
        $grupo += $cic
    }
    $result += [ordered]@{
        grupo = $_
        cic = $grupo
    }
    $ultGrupo = $_
}

$result | ConvertTo-Json -Depth 100 -Compress | Out-File "$prjPath\html\json\catecismo.json"
