Set-Location $PSScriptRoot

$result = [ordered]@{
    id = "VidaYEscritosDeSanPedroDeAlcantara"
    titulo = "Vida y Escritos de San Pedro de Alcantara"
    autor = "Rafael Sanz Valdivieso"
    editora = "BAC"
    ano = "1996"
    textoEstrutura = @"
Indice General	IX
 	Presentación de la serie	XIII
 	La mística del recogimiento	XVII
 	 	1. La espiritualidad de San Francisco	XVII
 	 	2. La vivencia espiritual franciscana	XVIII
 	 	3. La Observancia en España	XIX
 	 	4. Espiritualidad de la Observancia	XX
 	 	5. Seis grados de pobreza	XXII
 	 	6. La mística del recogimiento	XXV
 	 	7. Orígenes de la mística del recogimiento	XXVII
 	 	8. El recogimiento como novedad	XXIX
 	 	9. Historia y geografía	XXXI
 	 	10. Fuentes de la mística del recogimiento	XXXIV
 	 	11. Los cuatro primeros ensayos	XXXVI
 	 	12. Las codificaciones	XXXVIII
 	 	13. El nombre	XXXIX
 	 	14. Líneas internas de fuerza	XLI
 	 	15. Las fórmulas	XLIII
 	 	16. Recogidos y alumbrados de 1525	XLV
 	 	17. Recogimiento, erasmismo, luteranismo	XLVIII
 	 	18. Mística recogida y espiritualidad tradicional	LI
 	 	19. Mística recogida y teresiana	LII
 	 	Bibliografia fundamental	LIV
 	Introducción general	LV
 	Bibliografía general	LIX
 	Siglas	LXVII
 	Cronología de San Pedro de Alcántara y de otros acontecimientos franciscanos	LXIX
Parte primera - Vida de San Pedro de Alcantara	3
 	Capítulo 1. Familia y nacimiento	5
 	Capítulo 2. Educación y estudios	15
 	Capítulo 3. Toma de hábito y juventud religiosa	21
 	Capítulo 4. Oficios de San Pedro de Alcántara	31
 	Capítulo 5. Ministro provincial	37
 	Capítulo 6. Por tierras de Portugal	45
 	Capítulo 7. Apostolado en Extremadura	55
 	Capítulo 8. Por los desiertos de Santa Cruz y el Palancar	65
 	Capítulo 9. Sementera religiosa desde el Palancar	75
 	Capítulo 10. Comisario general de los Conventuales de vida reformada	91
 	Capítulo 11. Santidad de Fray Pedro de Alcántara	107
 	Capítulo 12. Muerte de Fray Pedro de Alcántara en Arenas	121
 	Capítulo 13. Glorificación y patronatos de San Pedro	141
 	Apéndice documental	151
 	 	Apéndice I: Cartas dirigidas a San Pedro de Alcántara	153
 	 	Apéndice II: Otros documentos	167
Parte segunda - Escritos de San Pedro de Alcantara	189
 	Producción literaria de San Pedro de Alcántara	191
 	 	Tratado de la Oración y Meditación	191
 	 	"Constituiciones de las Provincias franciscanas de San Gabriel y San José"	193
 	 	Comentario al salmo "Miserere mei, Domine"	194
 	 	Epistolario	195
 	 	Traducción de los "Soliloquios", de San Buenaventura	196
 	Tratado de la Oración y Meditación	199
 	Introducción	201
 	Apéndice	241
 	Texto del Tratado de la Oración y Meditación	249
 	Cartas de San Pedro de Alcántara	361
 	Ordenaciones de las Provincias de San Gabriel y de San José	389
 	Super Psalmum Miserere	409
 	Obras atribuidas: Breve introducción ara los que comienzan a servir a Nuestro Señor	421
 	Soliloquios de San Buenaventura	433
 	Indices	523
 	 	Indice bíblico	525
 	 	Indice de conceptos, lugares y personas	531
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
