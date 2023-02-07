Set-Location $PSScriptRoot

$result = [ordered]@{
    id = "TratadoDaOracaoEDaMeditacao"
    titulo = "Tratado da Oração e da Meditação"
    autor = "São Pedro de Alcântara"
    editora = "Editora Vozes"
    ano = "2013"
    textoEstrutura = @"
Sumário	5
À guisa de prefácio	9
Notícia biográfica sobre São Pedro de Alcântara	13
Primeira parte - Tratado da Oração e da Meditação	29
 	Capítulo I - Do fruto que se tira da oração e da meditação	31
 	Capítulo II - Da matéria da meditação	34
 	 	Segunda-feira	35
 	 	Terça-feira	38
 	 	Quarta-feira	42
 	 	Quinta-feira	46
 	 	Sexta-feira	48
 	 	Sábado	51
 	 	Domingo	55
 	Capítulo III - Do tempo e fruto destas meditações sobreditas	58
 	Capítulo IV - Das outras sete meditações da Sagrada Paixão e da maneira que havemos de ter em meditá-la	59
 	 	Segunda-feira	61
 	 	 	Da instituição do Santíssimo Sacramento	63
 	 	Terça-feira	64
 	 	Quarta-feira	67
 	 	Quinta-feira	71
 	 	Sexta-feira	74
 	 	Sábado	79
 	 	Domingo	81
 	Capítulo V - De seis coisas que podem intervir no exercício da oração	85
 	Capítulo VI - Da preparação que se requer para antes da oração	87
 	Capítulo VII - Da leitura	89
 	Capítulo VIII - Da meditação	90
 	Capítulo IX - Da ação de graças	91
 	Capítulo X - Do oferecimento	93
 	Capítulo XI - Da petição	95
 	 	Petição especial do amor de Deus	97
 	Capítulo XII - De alguns avisos que se devem ter neste santo exercício	101
 	 	Primeiro aviso	101
 	 	Segundo aviso	102
 	 	Terceiro aviso	102
 	 	Quarto aviso	103
 	 	Quinto aviso	104
 	 	Sexto aviso	105
 	 	Sétimo aviso	106
 	 	Oitavo aviso	107
Segunda parte - Tratado que fala da devoção	111
 	Capítulo I - Que coisa seja a devoção	113
 	Capítulo II - De nove coisas que ajudam a alcançar a devoção	116
 	Capítulo III - De dez coisas que impedem a devoção	118
 	Capítulo IV - Das tentações mais comuns que costumam fatigar os que se dão à oração e seus remédios	120
 	 	Primeiro aviso	120
 	 	Segundo aviso	122
 	 	Terceiro aviso	122
 	 	Quarto aviso	123
 	 	Quinto aviso	123
 	 	Sexto aviso	124
 	 	Sétimo aviso	124
 	 	Oitavo aviso	125
 	 	Nono aviso	125
 	Capítulo V - De alguns avisos necessários para os que se dão à oração	127
 	 	Primeiro aviso	127
 	 	Segundo aviso	129
 	 	Terceiro aviso	130
 	 	Quarto aviso	130
 	 	Quinto aviso	130
 	 	Sexto aviso	131
 	 	Sétimo aviso	132
 	 	Oitavo aviso	132
Breve introdução - Para os que começam a servir a Nosso Senhor	135
De três coisas que deve fazer quem quiser aproveitar muito em pouco tempo	140
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
