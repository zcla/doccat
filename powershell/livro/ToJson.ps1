Set-Location $PSScriptRoot

$result = [ordered]@{
    id = "ComoViverCom24HorasPorDia"
    titulo = "Como Viver com 24 Horas por Dia"
    autor = "Arnold Bennett"
    editora = "Auster"
    ano = "2019"
    # TODO Verificar se - como abaixo - a primeira linha contém "Título" e/ou "Página", e alertar
    textoEstrutura = @"
Título	Página
Sumário	5
Prefácio a esta edição	9
Capítulo I - O milagre diário	17
Capítulo II - O desejo de ir além da rotina	23
Capítulo III - Precauções para antes de começar	29
Capítulo IV - A causa dos problemas	35
Capítulo V - O tênis e a alma imortal	41
Capítulo VI - Relembrando a natureza humana	47
Capítulo VII - Controlando a mente	53
Capítulo VIII - A disposição reflexiva	59
Capítulo IX - O interesse nas artes	65
Capítulo X - Nada na vida é enfadonho	71
Capítulo XI - Leitura séria	77
Capítulo XII - Os perigos a evitar	83
"@
        estrutura = @()
}
$outFile = ".\fromWiki\$($result.id).json"
$result | ConvertTo-Json -Depth 100 | Out-File -FilePath $outFile

$spl = $result.textoEstrutura.Split([Environment]::NewLine);
$ids = @()
foreach ($texto in $spl) {
    $indent = 0
    $spl = $texto.Split("`t")
    while (-not $spl[$indent].Trim()) {
        $indent++
    }

    if ($spl.Length -ne ($indent + 2)) {
        throw "Algo errado não está certo"
    }

    $texto = $spl[$indent]
    $pagina = $spl[$indent + 1]
    
    switch ($ids.Length) {
        {$PSItem -eq $indent + 1} {
            # Mesmo nível atual
            $ids[$indent]++
        }
        {$PSItem -eq $indent} {
            # Um nível superior
            $ids += 1
        }
        {$PSItem -gt $indent + 1} {
            # Nível inferior
            $ids = $ids[0..$indent]
            $ids[$indent]++
        }
        Default {
            throw "Algo errado não está certo"
        }
    }

    $id = "$($ids[0])"
    for ($i = 1; $i -le $indent; $i++) {
        $id = "$($id)_$($ids[$i])"
    }

    $intPagina = $pagina
    try {
        $intPagina = [int]$pagina
    } catch {
        # deixa string
    }
    $result.estrutura += [ordered]@{
        id = "$id"
        indent = $indent
        texto = $texto
        pagina = $intPagina
    }
}
$result.Remove('textoEstrutura')

@"
`t`t`t`t`t<tr>
`t`t`t`t`t`t<td><a href="?pagina=livro&id=$($result.id)">$($result.titulo)</a></td>
`t`t`t`t`t`t<td>$($result.autor)</td>
`t`t`t`t`t`t<td>$($result.editora)</td>
`t`t`t`t`t`t<td class="text-end">$($result.ano)</td>
`t`t`t`t`t</tr>
"@ | Set-Clipboard

$outPath = (Get-Item -Path "$PSScriptRoot\..\..").FullName
$outFile = "$outPath\html\livro\$($result.id).json"
$result.Remove('id')
# if (Test-Path $outFile) {
#     throw "Arquivo já existe!"
# }
$result | ConvertTo-Json -Depth 100 | Out-File -FilePath $outFile
Write-Host "O trecho a inserir no index.html tá no clipboard."