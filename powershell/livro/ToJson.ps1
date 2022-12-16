$result = [ordered]@{
    id = "AAutoEstimaDoCristao"
    titulo = "A Auto-estima do Cristão"
    autor = "Michel Esparza"
    editora = "Quadrante"
    ano = "2008"
    textoEstrutura = @"
Introdução	5
Primeira parte - Os problemas do eu	11
 	O ser humano em busca da sua dignidade	13
 	 	A fonte de todos os problemas	13
 	 	O maior de todos os problemas	15
 	 	A origem da soberba	17
 	 	Três estágios da vida	20
 	 	O orgulho é uma mentira vital	23
 	 	O orgulho é competitivo e causa cegueira	26
 	 	Orgulho até na vida cristã: o perfeccionismo	30
 	 	A vaidade	35
 	Personalidade e afetividade: independência e dependência	40
 	 	As energias do coração	41
 	 	Afeto e desprendimento	44
 	 	Sensíveis e fortes	47
 	 	Conjugar dependência e independência	49
 	 	Liberdade interior e humildade	52
 	Auto-estima humilde ou auto-estima orgulhosa?	55
 	 	Diversos enfoques da auto-estima	55
 	 	Duas atitudes diante de nós mesmos	58
 	 	Egoísmo e egocentrismo	62
 	 	Onde começa a neurose?	64
Segunda parte - Pautas para uma possível solução	69
 	Humildade e verdade	71
 	 	Humildade e auto-estima	71
 	 	A humildade evita tanto a arrogância como a auto-rejeição	74
 	 	O esquecimento próprio e a falsa humildade	76
 	 	A verdadeira humildade e liberdade do cristão	78
 	 	Liberdade e entrega por amor	82
 	A purificação do coração	85
 	 	Mudar os alicerces da personalidade	85
 	 	Pecados e virtudes	87
 	 	A graça que dignifica e sara	89
 	Só o amor de Deus oferece soluções estáveis	92
 	 	"Respeitos humanos" e "respeitos divinos"	92
 	 	Uma vida inteira à procura do que já se tem	94
 	 	Não é fácil situar-se na perspectiva do amor de Deus	101
 	 	O filho mais velho da parábola	103
 	Diversas manifestações do amor de Deus	107
 	 	Filiação divina	107
 	 	Amizade recíproca com Cristo	110
 	 	Valemos todo o sangue de Cristo	118
 	O amor misericordioso	124
 	 	O que significa ser misericordioso?	126
 	 	Cristo revela a misericórdia divina	129
 	 	Pode-se estar orgulhoso da própria fraqueza?	131
 	 	Duas condições: amor recíproco e boa vontade	135
 	 	Vida de infância espiritual	142
 	 	Admiráveis perspectivas de futuro	147
Epílogo: "ama-me tal como és"	153
Índice	157
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

    $result.estrutura += [ordered]@{
        id = "$id"
        indent = $indent
        texto = $texto
        pagina = [int]$pagina
    }
}
$result.Remove('textoEstrutura')

$outPath = (Get-Item -Path "$PSScriptRoot\..\..").FullName
$outFile = "$outPath\html\livro\$($result.id).json"
$result.Remove('id')
# if (Test-Path $outFile) {
#     throw "Arquivo já existe!"
# }
$result | ConvertTo-Json -Depth 100 | Out-File -FilePath $outFile
