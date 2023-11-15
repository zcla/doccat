$scriptPath = Get-Item ($MyInvocation.MyCommand.Path)
Set-Location $scriptPath.PSParentPath
$fileName = ".\$($scriptPath.Name.split('.')[0]).json"

Write-Host "Inicializando" -ForegroundColor Cyan -NoNewline
. ..\..\..\utils\JsonDoc.ps1
$result = [JsonDoc_Elemento]::fromJson((Get-Content -Path .\03parse.json))
Write-Host " ok" -ForegroundColor Green

Write-Host "Consertando" -ForegroundColor Cyan -NoNewline
if (Test-Path $fileName) {
	Write-Host " já feito" -ForegroundColor Green
} else {
    Write-Host " fazendo..." -ForegroundColor Yellow

    Write-Host "  1Cr 11,0" -ForegroundColor Cyan -NoNewline
    $result.getConteudoPorId('i-paralipomenon').getConteudoPorId('11').GetConteudoPorId('0').id = '40'
    Write-Host " => 1Cr 11,40" -ForegroundColor Green

    Write-Host "  Eclo Prólogo,0" -ForegroundColor Cyan -NoNewline
    $result.getConteudoPorId('ecclesiasticus').getConteudoPorId('Prólogo').getConteudoPorId('0').id = ''
    Write-Host " => Eclo Prólogo,`"`"" -ForegroundColor Green

    Write-Host "  Br 6,0" -ForegroundColor Cyan -NoNewline
    $result.getConteudoPorId('baruch').getConteudoPorId('6').getConteudoPorId('0').id = ''
    Write-Host " => Br 6,`"`"" -ForegroundColor Green

    foreach ($livro in $result.getConteudo()) {
        Write-Host "  $($livro.id)" -ForegroundColor Cyan -NoNewline
        foreach ($capitulo in $livro.getConteudo()) {
            Write-Host " $($capitulo.id)" -ForegroundColor Cyan -NoNewline
            $versiculos = $capitulo.getConteudo() | Where-Object -FilterScript { $true } # copia, pra não dar erro "Collection was modified"
            foreach ($versiculo in $versiculos) {
                $versiculoId = $versiculo.id

                $proximoVersiculo = '?'
                # 1, 2, ...
                if ($versiculoId -match '^\d+$') {
                    $proximoVersiculo = "$(([int]$versiculoId) + 1)"
                }
                # 1a, 1b, ... 1z, 1aa, 1bb, ...
                if ($versiculoId -match '^\d+[a-z]+$') {
                    $intPart = $versiculoId -replace '[a-z]+', ''
                    $charPart = $versiculoId -replace '\d+', ''
                    $nextChar = [string]([char]([int]([char]($charPart[0])) + 1)) * $charPart.Length
                    if ($nextChar -eq '{') {
                        $nextChar = 'aa'
                    }
                    $proximoVersiculo = "$intPart$nextChar"
                }
                # (1), (2), ...
                if ($versiculoId -match '^\(\d+\)$') {
                    continue
                }
                # vazio (Br 6)
                if ($versiculoId -eq '') {
                    continue
                }
                # ???
                if ($proximoVersiculo -eq '?') {
                    throw "Inesperado!"
                }

                if (-not $capitulo.getConteudoPorId($proximoVersiculo)) {
                    # Busca versículos omitidos
                    $regex = [regex]"\( ($proximoVersiculo) \)"
                    $mtch = $regex.Match(($versiculo.conteudo.texto | Out-String))
                    if ($mtch.Success) {
                        $capitulo.versiculos.$versiculoId.texto = $regex.Replace($versiculo.texto, '').Trim()
                        Write-Host " [versículo $versiculoId alterado]" -ForegroundColor Green -NoNewline
                        $capitulo.versiculos."($proximoVersiculo)" = [ordered]@{
                            texto = ""
                        }
                        Write-Host " [versículo $proximoVersiculo inserido]" -ForegroundColor Green -NoNewline
                    }

                    # Busca duplas de versículos omitidos (regex simplificada porque só ocorre em Eclo 9 e Eclo 29)
                    $regex = [regex]"\(($proximoVersiculo)\.? (\d+)\)"
                    $mtch = $regex.Match(($versiculo.conteudo.texto | Out-String))
                    if ($mtch.Success) {
                        $capitulo.versiculos.$versiculoId.texto = $regex.Replace($versiculo.texto, '').Trim()
                        Write-Host " [versículo $versiculoId alterado]" -ForegroundColor Green -NoNewline
                        $capitulo.versiculos."($proximoVersiculo)" = [ordered]@{
                            texto = ""
                        }
                        Write-Host " [versículo $proximoVersiculo inserido]" -ForegroundColor Green -NoNewline
                        $proximoVersiculo = $mtch.Groups[2].Value
                        $capitulo.versiculos."($proximoVersiculo)" = [ordered]@{
                            texto = ""
                        }
                        Write-Host " [versículo $proximoVersiculo inserido]" -ForegroundColor Green -NoNewline
                    }

                    # Busca versículos que não tiveram quebra de linha
                    $regex = [regex]"(?s)(^.+) ($proximoVersiculo) (.+)$"
                    $mtch = $regex.Match(($versiculo.conteudo.texto | Out-String))
                    if ($mtch.Success) {
                        if ($versiculo.conteudo.Count -ne 1) {
                            Write-Host "O que fazer?"
                        }
                        $v1 = $mtch.Groups[1].Value
                        $numVersiculo = $mtch.Groups[2].Value
                        $v2 = $mtch.Groups[3].Value
                        if ($capitulo.getConteudoPorId($numVersiculo)) {
                            Write-Host " [versículo $numVersiculo já existe]" -ForegroundColor Red -NoNewline
                        } else {
                            $versiculo.conteudo[0].setTexto($v1)
                            Write-Host " [versículo $($versiculo.id) alterado]" -ForegroundColor Green -NoNewline
                            $versiculoNovo = [JsonDoc_Texto]::new($numVersiculo, 'versiculo')
                            $versiculoNovo.addConteudo('texto', $v2)
Write-Host "[$($capitulo.conteudo.id -join ' ')]" -NoNewline
                            $capitulo.addConteudoAfter($versiculoNovo, $versiculo)
Write-Host "[$($capitulo.conteudo.id -join ' ')]" -NoNewline
                            Write-Host " [versículo $numVersiculo inserido]" -ForegroundColor Green -NoNewline
                        }
                    }
                }
            }
        }
        Write-Host ""
    }

    Write-Host "Gravando" -ForegroundColor Cyan -NoNewline
    $result.toJson() | Out-File (New-Item $fileName -Force)
    Write-Host " ok" -ForegroundColor Green
}

Write-Host "Fim" -ForegroundColor Cyan
