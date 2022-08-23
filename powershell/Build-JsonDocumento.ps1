# Lê os arquivos estáticos dos documentos e monta um JSON com os dados necessários aos scripts JavaScript

$prjPath = ((Get-Item $MyInvocation.MyCommand.Path).Directory.Parent.FullName)

Clear-Host

Write-Host "Inicializando" -ForegroundColor Cyan
.\Import-PowerHTML.ps1

$pathDocumentos = "$prjPath\html\documento"

$documentos = Get-ChildItem -Path $pathDocumentos | Where-Object { $_.name -ne '(modelo)' }

$result = [ordered]@{}

$documentos | ForEach-Object {
    $docName = $_.Name
    $path = "$pathDocumentos\$docName\index.html"
    Write-Host "  $docName" -ForegroundColor Cyan
    $html = ConvertFrom-Html -Path "$path"
    $refs = $html.SelectNodes('//ref-doc[@nome="' + $docName + '"]')
    $documento = @()
    $refs | ForEach-Object {
        $paragrafo = $_.InnerText
        $documento += $paragrafo
    }
    $result[$docName] = [ordered]@{}
    if ($documento) {
        $result[$docName].paragrafo = $documento
    }
}

$result | ConvertTo-Json -Depth 100 -Compress | Out-File "$prjPath\html\json\documento.json"
