Set-Location $PSScriptRoot

$result = [ordered]@{
    id = "AsTresViasEAsTresConversoes"
    titulo = "As Três Vias e as Três Conversões"
    autor = "Réginald Garrigou Lagrange"
    editora = "Permanência"
    ano = "2011"
    textoEstrutura = @"
Sumário	7
Prefácio	9
Prólogo	11
Capítulo I - A vida da graça e o valor da primeira conversão	15
 	Necessidade da vida interior	15
 	Qual é o princípio ou a fonte da vida interior?	18
 	A realidade da graça e de nossa filiação divina adotiva	21
 	A vida eterna começada	24
 	O valor da verdadeira conversão	28
 	As três idades da vida espiritual	36
Capítulo II - A segunda conversão: entrada na via iluminativa	41
 	A segunda conversão dos apóstolos	43
 	Como deve ser nossa segunda conversão - as imperfeições que a tornam necessária	46
 	Os principais motivos que devem inspirar a segunda conversão e quais são seus frutos	50
Capítulo III - A terceira conversão: ou transformação da alma, entrada na via unitiva dos perfeitos	57
 	A descida do Espírito Santo sobre os apóstolos	58
 	Quais foram os efeitos da descida do Espírito Santo?	60
 	A purificação do espírito, necessária à perfeição cristã	65
 	A necessidade da purificação do espírito	66
 	Como Deus purifica a alma no momento desta terceira conversão ou transformação?	68
 	Oração ao Espírito Santo	73
 	Consagração e oração ao Espírito Santo	73
Nota do editor explicando que o capítulo IV foi omitido desta edição a conselho do autor	74
Capítulo V - Características de cada uma das fases da vida espiritual	75
 	A fase dos principiantes	76
 	A fase dos avançados	81
 	A fase dos perfeitos	86
Capítulo VI - A paz no reino de Deus, prelúdio da vida no céu	89
 	O despertar divino	89
 	A viva chama	91
 	Pax in veritate	95
Nota final - O chamado à contemplação infusa dos mistérios da fé	97
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
