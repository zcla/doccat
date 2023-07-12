Set-Location $PSScriptRoot

$result = [ordered]@{
    id = "AVidaIntelectual"
    titulo = "A vida intelectual"
    autor = "Antonin-Dalmace Sertillanges"
    editora = "Kírion"
    ano = "2019"
    textoEstrutura = @"
Título	Página
Sumário	5
Prefácio à edição brasileira	11
Prefácio à terceira edição	15
Prefácio à segunda edição	17
Prefácio	25
I. A vocação intelectual	27
 	I. O intelectual é um consagrado	27
 	II. O intelectual não é um isolado	33
 	III. O intelectual pertence a seu tempo	34
II. As virtudes de um intelectual cristão	37
 	I. As virtudes comuns	37
 	II. A virtude própria do intelectual	42
 	III. O espírito de oração	45
 	IV. A disciplina do corpo	48
III. A organização da vida	55
 	I. Simplificar	55
 	II. Guardar a solidão	58
 	III. Cooperar com seus pares	63
 	IV. Cultivar as relações necessárias	66
 	V, Conservar a dose necessária de ação	69
 	VI. Manter em tudo o silêncio interior	73
IV. O tempo do trabalho	75
 	I. O trabalho permanente	75
 	II. O trabalho noturno	84
 	III. As manhãs e as noites	88
 	IV. Os momentos de plenitude	92
V. O campo de trabalho	99
 	I. A ciência comparada	99
 	II. O tomismo, quadro ideal do saber	108
 	III. A especialidade	111
 	IV. Os sacrifícios necessários	113
VI. O espírito de trabalho	115
 	I. O fervor da investigação	115
 	II. A concentração	118
 	III. A submissão à verdade	120
 	IV. Os desenvolvimentos	124
 	V. O senso do mistério	127
VII. A preparação do trabalho	131
 	A - A leitura	131
 	 	I. Ler pouco	131
 	 	II. Escolher	134
 	 	III. Quatro espécies de leitura	136
 	 	IV. O contato com os gênios	139
 	 	V. Conciliar em vez de opor	144
 	 	VI. Apropriar-se e viver	146
 	B - A organização da memória	152
 	 	I. O que se deve reter	152
 	 	II. Em que ordem reter	154
 	 	III. Como fazer para reter	157
 	C - As notas	161
 	 	I. Como anotar	161
 	 	II. Como classificar suas notas	166
 	 	III. Como utilizar suas notas	168
VIII. O trabalho criador	171
 	I. Escrever	171
 	II. Desapegar-se de si mesmo e do mundo	177
 	III. Ser constante, paciente e perseverante	182
 	IV. Tudo fazer bem e tudo terminar	190
 	V. Não empreender nada que esteja acima da sua capacidade	193
IX. O trabalhador e o homem	197
 	I. Manter contato com a vida	197
 	II. Saber se descontrair	202
 	III. Aceitar as provações	206
 	IV. Gozar as alegrias	211
 	V. Anelar os frutos	212
Dezesseis conselhos de São Tomás de Aquino para adquirir o tesouro da ciência	217
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
