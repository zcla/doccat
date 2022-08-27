Set-Location $PSScriptRoot
$prjPath = (Get-Item $PSScriptRoot).Parent.Parent.FullName
$id = (Get-Item $PSCommandPath).Name -replace '\.ps1', ''

Write-Host "Inicializando" -ForegroundColor Cyan
..\utils\Import-ModulePowerHTML.ps1

$config = Get-Content -Path "$prjPath\config\config.json" | ConvertFrom-Json

Write-Host "Biblia" -ForegroundColor Cyan

$fileName = "$prjPath\temp\json\$id.json"
Write-Host "  JSON" -ForegroundColor Cyan -NoNewline
If (Test-Path $fileName) {
    Write-Host " ok" -ForegroundColor Green
} Else {
    Write-Host " gerando..." -ForegroundColor Yellow

    $result = [ordered]@{}
    ForEach ($keyLivro In $dados.Keys) {
        $sigla = $config.download.'Biblia_vatican.va_lt'.'mapa-livro'.$keyLivro
        Write-Host "    $sigla ($keyLivro)" -ForegroundColor Cyan -NoNewline
        $result.$sigla = [ordered]@{
            "#fonte" = $dados.$keyLivro.fonte
        }
        $htmlDom = ConvertFrom-Html -Content $dados.$keyLivro.texto
        $ancoras = $htmlDom.SelectNodes("//a[@name]") | Where-Object { $_.InnerText }
        If ($ancoras.Count -eq 0) {
            $ancoras = $htmlDom.SelectNodes("//p") | Where-Object { $_.InnerHTML -match '\<br\>' }
        }
        Write-Host " ($($ancoras.Count) capítulos)" -ForegroundColor Green -NoNewline
        ForEach ($ancora In $ancoras) {
            $htmlCapitulo = $ancora
            While ($htmlCapitulo.Name -ne 'p') {
                $htmlCapitulo = $htmlCapitulo.ParentNode
            }
            $fase = 'inicio'
            $numCapitulo = '-'
            $ultVersiculo = '*'
            ForEach ($child In $htmlCapitulo.ChildNodes) {
                $texto = ($child.InnerText -replace "&nbsp;", " ").Trim()
                switch ($true) {
                    (($fase -eq 'inicio') -and ($child.Name -eq '#text')) {
                        If ($texto) {
                            $fase = 'versiculos'
                            $result.$sigla.$numCapitulo = [ordered]@{}
                            Write-Host " $numCapitulo" -ForegroundColor Cyan -NoNewline
                        } Else {
                            Continue
                        }
                    }

                    (($fase -eq 'inicio') -and ($child.Name -eq 'br')) {
                        Continue
                    }

                    (($fase -eq 'inicio') -and ($child.Name -eq 'i')) {
                        # Aparentemente isso só acontece antes do Sl 107
                        Continue
                    }

                    (($fase -eq 'inicio') -and (@('a', 'b', 'font') -contains $child.Name)) {
                        If ($texto) {
                            $numCapitulo = $texto.Trim()
                            If ($sigla -eq 'Sl') {
                                If ($numCapitulo.StartsWith('LIBER ')) {
                                    Continue
                                }
                                If ($numCapitulo.StartsWith('PSALMUS ')) {
                                    $numCapitulo = $numCapitulo.Substring(8)
                                }
                            }
                            Write-Host " $numCapitulo" -ForegroundColor Cyan -NoNewline
                            $result.$sigla.$numCapitulo = [ordered]@{}
                            $fase = 'titulo'
                        }
                        Continue
                    }

                    (($fase -eq 'titulo') -and ($child.Name -eq '#text')) {
                        If ($texto) {
                            If ($result.$sigla.$numCapitulo.'#vulgata') {
                                $result.$sigla.$numCapitulo.'#vulgata' += "`n`r$texto" # Precaução; nunca chega aqui
                            } Else {
                                $result.$sigla.$numCapitulo.'#vulgata' = $texto
                            }
                        }
                        Continue
                    }

                    (($fase -eq 'titulo') -and ($child.Name -eq 'br')) {
                        $fase = 'versiculos'
                        Continue
                    }

                    (($fase -eq 'versiculos') -and (@('#text', 'i') -contains $child.Name)) {
                        If ($texto) {
                            $versiculoExtra = ''
                            If ($texto -match '\(\d\)$') {
                                $versiculoExtra = '(' + $texto.Split('(')[-1]
                                $texto = $texto.Substring(0, $texto.Length - $versiculoExtra.Length).Trim()
                            }
                            If ($child.Name -eq 'i') {
                                $texto = "<i>$texto</i>"
                            }

                            $numVersiculo = ''
                            If ($texto -match '^\(?\d{1,3}[a-z]{0,2}\)?( |\\r\\n)') {
                                $numVersiculo = $texto.Split(' ')[0]
                                $texto = $texto.Substring($numVersiculo.Length).Trim()
                            }
                            If ($texto -match '^\d{1,3}$') {
                                $numVersiculo = $texto
                                $texto = ''
                            }

                            # >>> Gambiarras por características ou defeitos na fonte >>>
                            $sigCap = "$sigla $numCapitulo"
                            # Textos com o primeiro versículo sem número
                            If (@('Br 6', 'Jz 19', 'Nm 1') -contains $sigCap) {
                                If ($result.$sigla.$numCapitulo.Keys.Count -eq 0) {
                                    $numVersiculo = '-'
                                }
                            }
                            # Outros casos
                            $sigCapVer = "$sigla $numCapitulo $numVersiculo"
                            switch ($sigCapVer) {
                                '1Cr 11 0' {
                                    $numVersiculo = '40'
                                }
                                'At 17 ' {
                                    If ($result.$sigla.$numCapitulo.Keys.Count -eq 0) {
                                        $numVersiculo = '1'
                                        $texto = $texto.Substring(1)
                                    }
                                }
                            }
                            # <<< Gambiarras por características ou defeitos na fonte <<<
                            
                            If ($numVersiculo) {
                                If ($numVersiculo -match '^\(') {
                                    $result.$sigla.$numCapitulo."$numVersiculo" = ""
                                    $numVersiculo = ''
                                    If ($texto -match '^\(?\d{1,3}[a-z]?\)? ') {
                                        $numVersiculo = $texto.Split(' ')[0]
                                        $texto = $texto.Substring($numVersiculo.Length).Trim()
                                        $result.$sigla.$numCapitulo."$numVersiculo" = $texto
                                    }
                                } Else {
                                    $result.$sigla.$numCapitulo."$numVersiculo" = $texto
                                }    
                                $ultVersiculo = $numVersiculo
                            } Else {
                                If ($result.$sigla.$numCapitulo."$ultVersiculo") {
                                    $result.$sigla.$numCapitulo."$ultVersiculo" += "`r`n"
                                }
                                $result.$sigla.$numCapitulo."$ultVersiculo" += $texto
                            }

                            If ($versiculoExtra) {
                                $result.$sigla.$numCapitulo."$versiculoExtra" = ""
                            }
                        }
                        Continue
                    }

                    (($fase -eq 'versiculos') -and ($child.Name -eq 'br')) {
                        Continue
                    }

                    (($fase -eq 'versiculos') -and ($child.Name -eq 'font')) {
                        Continue
                    }

                    Default {
                        Throw "Não sei tratar."
                    }
                }
            }
        }
        Write-Host ""
        # Referências: https://html-agility-pack.net/documentation   https://devhints.io/xpath
    }

    $temp = $result
    $result = [ordered]@{}
    ForEach ($livro In $config.biblia.livro) {
        $sigla = "$($livro.sigla)"
        $result.$sigla = $temp.$sigla
    }

    Write-Host "    Gravando" -ForegroundColor Cyan -NoNewline
    $result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
    Write-Host " ok" -ForegroundColor Green
}
