# Baixa páginas do site vatican.va.

$prjPath = ((Get-Item $MyInvocation.MyCommand.Path).Directory.Parent.FullName)

Clear-Host

Write-Host "Inicializando" -ForegroundColor Cyan
.\Import-ModulePowerHTML.ps1

$config = Get-Content -Path "$prjPath\config\config.json" | ConvertFrom-Json

Write-Host "Biblia" -ForegroundColor Cyan
$id = 'Biblia_vatican.va_lt'
$fileName = "$prjPath\temp\download\$id.json"

Write-Host "  Download" -ForegroundColor Cyan -NoNewline
If (Test-Path $fileName) {
    Write-Host " ok" -ForegroundColor Green
} Else {
    Write-Host " fazendo..." -ForegroundColor Yellow

    $result = [ordered]@{}
    ForEach ($url In $config.download.$id.urls) {
        Write-Host "    $url" -ForegroundColor Cyan -NoNewline
        $iwr = Invoke-WebRequest $url
        $urlsLivros = $iwr.Links | Where-Object { $_.href -match '^nova-vulgata_(v|n)t_' }
        Write-Host " $($urlsLivros.Length) livros" -ForegroundColor Green
        ForEach ($urlLivro In $urlsLivros) {
            #####
            $livro = $urlLivro.href -replace '^nova-vulgata_(v|n)t_(.*)_lt.html', '$2'
            Write-Host "      $livro" -ForegroundColor Cyan -NoNewline
            $iwrLivro = Invoke-WebRequest "$($url.substring(0, $url.LastIndexOf('/')))/$($urlLivro.href)"
            $result.$livro = "$($iwrLivro.Content)" # TODO Adicionar fonte (url) e nome do livro (tem no link)
            Write-Host " $($result.$livro.Length) bytes" -ForegroundColor Green
        }
    }

    Write-Host "    Gravando" -ForegroundColor Cyan -NoNewline
    $result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
    Write-Host " ok" -ForegroundColor Green
}

Write-Host "  Lendo" -ForegroundColor Cyan -NoNewline
$dados = Get-Content $fileName | ConvertFrom-Json -AsHashtable
Write-Host " $($dados.Keys.Count) livros" -ForegroundColor Green

$fileName = "$prjPath\temp\json\$id.json"

Write-Host "  JSON" -ForegroundColor Cyan -NoNewline
If (Test-Path $fileName) { Remove-Item $fileName } # TODO Excluir
If (Test-Path $fileName) {
    Write-Host " ok" -ForegroundColor Green
} Else {
    Write-Host " gerando..." -ForegroundColor Yellow

    $result = [ordered]@{}
    ForEach ($keyLivro In $dados.Keys) {
        $sigla = $config.download.'Biblia_vatican.va_lt'.'mapa-livro'.$keyLivro
        Write-Host "    $sigla ($keyLivro)" -ForegroundColor Cyan -NoNewline
        $result.$sigla = [ordered]@{}
        $htmlDom = ConvertFrom-Html -Content $dados.$keyLivro
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
                            If ($result.$sigla.$numCapitulo.'#comment') {
                                $result.$sigla.$numCapitulo.'#comment' += "`n`r$texto" # Precaução; nunca chega aqui
                            } Else {
                                $result.$sigla.$numCapitulo.'#comment' = $texto
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
                            If ($texto -match '^\(?\d{1,3}[a-z]?\)? ') {
                                $numVersiculo = $texto.Split(' ')[0]
                                $texto = $texto.Substring($numVersiculo.Length).Trim()
                            }

                            # >>> Gambiarras por defeitos no texto >>>
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
                            # TODO Muitas gambiarras pendentes; procuar "*" no Biblia_vatican.va_lt.json
                            # <<< Gambiarras por defeitos no texto <<<
                            
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

    Write-Host "    Gravando" -ForegroundColor Cyan -NoNewline
    $result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
    Write-Host " ok" -ForegroundColor Green
}
