Set-Location $PSScriptRoot

$result = [ordered]@{
    id = "AConstancia"
    titulo = "A Constância"
    autor = "Rafael Llano Cifuentes"
    editora = "Quadrante"
    ano = "2019"
    textoEstrutura = @"
Sumário	3
Uma condição indispensável	5
 	Não há constância sem ideal	5
 	O ideal não se realiza sem constância	8
 	A constância e o desenvolvimento da vida cristã	11
Os caminhos da constância	19
 	Domínio do temperamento	20
 	Vencer inclinações, costumes e hábitos	25
 	A luta contra a vaidade	27
 	A nossa verdadeira imagem	29
 	A superação do sensível	35
 	A diligência e a laboriosidade	39
 	Ultrapassar os obstáculos com espírito esportivo	43
Duas palavras finais	51
 	Confiar	51
 	Amar	55
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
