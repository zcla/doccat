$scriptPath = Get-Item ($MyInvocation.MyCommand.Path)
Set-Location $scriptPath.PSParentPath
$fileName = ".\$($scriptPath.Name.split('.')[0]).json"

Write-Host "Inicializando" -ForegroundColor Cyan -NoNewline
$result = Get-Content -Path .\03parse.json | ConvertFrom-Json -AsHashtable
Write-Host " ok" -ForegroundColor Green

Write-Host "Consertando" -ForegroundColor Cyan -NoNewline
if (Test-Path $fileName) {
	Write-Host " já feito" -ForegroundColor Green
} else {
    Write-Host " fazendo..." -ForegroundColor Yellow

    $result.livros.'i-paralipomenon'.capitulos.'11'.versiculos.'40' = $result.livros.'i-paralipomenon'.capitulos.'11'.versiculos.'0'
    Write-Host "  1Cr 11,40 adicionado" -ForegroundColor Green
    $result.livros.'i-paralipomenon'.capitulos.'11'.versiculos.Remove('0')
    Write-Host "  1Cr 11,0 removido" -ForegroundColor Green

    $result.livros.'ecclesiasticus'.capitulos.'Prólogo'.versiculos.'' = $result.livros.'ecclesiasticus'.capitulos.'Prólogo'.versiculos.'0'
    Write-Host "  Eclo Prólogo,<nada> adicionado" -ForegroundColor Green
    $result.livros.'ecclesiasticus'.capitulos.'Prólogo'.versiculos.Remove('0')
    Write-Host "  Eclo Prólogo,0 removido" -ForegroundColor Green

    $result.livros.'baruch'.capitulos.'6'.versiculos.'' = $result.livros.'baruch'.capitulos.'6'.versiculos.'0'
    Write-Host "  Br 6,<nada> adicionado" -ForegroundColor Green
    $result.livros.'baruch'.capitulos.'6'.versiculos.Remove('0')
    Write-Host "  Br 6,0 removido" -ForegroundColor Green

    foreach ($keyLivro in $result.livros.Keys) {
        Write-Host "  $keyLivro" -ForegroundColor Cyan -NoNewline
        $livro = $result.livros.$keyLivro
        foreach ($keyCapitulo in $livro.capitulos.Keys) {
            Write-Host " $keyCapitulo" -ForegroundColor Cyan -NoNewline
            $capitulo = $livro.capitulos.$keyCapitulo
            $versiculosKeys = $capitulo.versiculos.Keys | Where-Object -FilterScript { $true } # copia, pra não dar erro "Collection was modified"
            foreach ($keyVersiculo in $versiculosKeys) {
                $versiculo = $capitulo.versiculos.$keyVersiculo
# if ("$keyLivro $keyCapitulo $keyVersiculo" -eq 'ecclesiasticus 9 9') {
# Write-Host "!"
# }

                $proximoVersiculo = '?'
                # 1, 2, ...
                if ($keyVersiculo -match '^\d+$') {
                    $proximoVersiculo = "$(([int]$keyVersiculo) + 1)"
                }
                # 1a, 1b, ... 1z, 1aa, 1bb, ...
                if ($keyVersiculo -match '^\d+[a-z]+$') {
                    $intPart = $keyVersiculo -replace '[a-z]+', ''
                    $charPart = $keyVersiculo -replace '\d+', ''
                    $nextChar = [string]([char]([int]([char]($charPart[0])) + 1)) * $charPart.Length
                    if ($nextChar -eq '{') {
                        $nextChar = 'aa'
                    }
                    $proximoVersiculo = "$intPart$nextChar"
                }
                # (1), (2), ...
                if ($keyVersiculo -match '^\(\d+\)$') {
                    continue
                }
                # vazio (Br 6)
                if ($keyVersiculo -eq '') {
                    continue
                }
                # ???
                if ($proximoVersiculo -eq '?') {
                    throw "Inesperado!"
                }

                if (-not $capitulo.versiculos.$proximoVersiculo) {
                    # Busca versículos omitidos
                    $regex = [regex]"\( ($proximoVersiculo) \)"
                    $mtch = $regex.Match($versiculo.texto)
                    if ($mtch.Success) {
                        $capitulo.versiculos.$keyVersiculo.texto = $regex.Replace($versiculo.texto, '').Trim()
                        Write-Host " [versículo $keyVersiculo alterado]" -ForegroundColor Green -NoNewline
                        $capitulo.versiculos."($proximoVersiculo)" = [ordered]@{
                            texto = ""
                        }
                        Write-Host " [versículo $proximoVersiculo inserido]" -ForegroundColor Green -NoNewline
                    }

                    # Busca duplas de versículos omitidos (regex simplificada porque só ocorre em Eclo 9 e Eclo 29)
                    $regex = [regex]"\(($proximoVersiculo)\.? (\d+)\)"
                    $mtch = $regex.Match($versiculo.texto)
                    if ($mtch.Success) {
                        $capitulo.versiculos.$keyVersiculo.texto = $regex.Replace($versiculo.texto, '').Trim()
                        Write-Host " [versículo $keyVersiculo alterado]" -ForegroundColor Green -NoNewline
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
                    $mtch = $regex.Match($versiculo.texto)
                    if ($mtch.Success) {
                        $v1 = $mtch.Groups[1].Value
                        $numVersiculo = $mtch.Groups[2].Value
                        $v2 = $mtch.Groups[3].Value
                        if ($capitulo.versiculos.$numVersiculo) {
                            Write-Host " [versículo $numVersiculo já existe]" -ForegroundColor Red -NoNewline
                        } else {
                            $capitulo.versiculos.$keyVersiculo.texto = $v1
                            Write-Host " [versículo $keyVersiculo alterado]" -ForegroundColor Green -NoNewline
                            $capitulo.versiculos.$numVersiculo = [ordered]@{
                                texto = $v2
                            }
                            Write-Host " [versículo $numVersiculo inserido]" -ForegroundColor Green -NoNewline
                        }
                    }
                }
            }
        }
        Write-Host ""
    }

    Write-Host "Gravando" -ForegroundColor Cyan -NoNewline
    $result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
    Write-Host " ok" -ForegroundColor Green
}

Write-Host "Fim" -ForegroundColor Cyan
