Clear-Host

Function LogFileName($str) {
    $item = Get-Item $PSCommandPath
    $result = "$($item.Directory.FullName)\..\log\$($item.Name)($str).log"
    return $result
}

Function JsonFileName($str) {
    $item = Get-Item $PSCommandPath
    $result = "$($item.Directory.FullName)\..\download\bibliacatolica.com.br"
    If ($str) {
        $result += ".$str"
    }
    $result += ".json"
    return $result
}

Function StringNormalize($str) {
    return [Text.Encoding]::ASCII.GetString([Text.Encoding]::GetEncoding("Cyrillic").GetBytes($str))
}

# Lista de bíblias
Write-Host "Lista de bíblias"
$request = Invoke-WebRequest "https://www.bibliacatolica.com.br/"
$biblias = @()
If ($request.StatusCode -eq 200) {
    $mm4 = $request.ParsedHtml.getElementById("mm-4")
    $ulBiblias = $mm4.getElementsByClassName("mm-listview")[0]
    ForEach ($liBiblia In $ulBiblias.children) {
        $url = $liBiblia.children[0].href
        $nome = $liBiblia.children[0].innerText.Trim()
        $lang = $liBiblia.children[0].children[0].className.Split(' ')[1].Split('-')[1]
        $biblias += [ordered]@{
            url = $url -replace '^([^\/]+\/\/[^\/]+\/[^\/]+\/).+$', '$1'
            nome = $nome
            lang = $lang
        }
    }
    $jsonOutputFile = JsonFileName
    $json = $biblias | ConvertTo-Json -Depth 100 -Compress
    $json | Out-File $jsonOutputFile
} Else {
    Throw "Invoke-WebRequest: erro $request.StatusCode"
}

# Bíblias
Write-Host "Bíblias"
ForEach ($biblia In $biblias) {
    $result = [ordered]@{
        nome = $biblia.nome
        url = $biblia.url
        idioma = $biblia.lang
        grupos = [ordered]@{}
    }
    $jsonOutputFile = (JsonFileName $result.nome)
    If (Test-Path $jsonOutputFile) {
        Write-Host "`t[skip] [$($biblia.lang)] $($biblia.nome)"
        Continue
    }

    Start-Transcript (LogFileName $result.nome) -Force
    Try {
        # Bíblia
        Write-Host "`t[$($biblia.lang)] $($biblia.nome)"
        $requestB = Invoke-WebRequest $biblia.url
        If ($requestB.StatusCode -eq 200) {
            # Livros
            $selectLivros = $requestB.ParsedHtml.body.getElementsByClassName("livros")[0]
            $optionsLivro = $selectLivros.getElementsByTagName("option")
            ForEach ($optionLivro In $optionsLivro) {
                If ($optionLivro.text -eq " ") {
                    Continue
                }
                $grupo = $optionLivro.parentNode.label
                If (-not ($result.grupos."$grupo")) {
                    Write-Host "`t`t$grupo"
                    $result.grupos."$grupo" = [ordered]@{
                        nome = $grupo
                        livros = [ordered]@{}
                    }
                }
                $livro = $optionLivro.value
                $nomeLivro = $optionLivro.text
                $urlLivro = $nomeLivro
                $findReplace = @( @( " ", "-" ), @( "º", "" ), @( "\(", "" ), @( "\)", "" ), @( "\.", "" ), @( "=", "" ), @( "æ", "ae" ), @( "ă", "" ), @( "ţ", "") )
                ForEach ($fr In $findReplace) {
                    $urlLivro = $urlLivro -replace $fr[0], $fr[1]
                }
                $urlLivro = "$($biblia.url)$(StringNormalize($urlLivro).ToLower())/"
                $findReplace = @( @( "\?", "" ), @( "\?", "" ) ) # O segundo é inútil; é só pra ele não transformar em um array unidimensional
                ForEach ($fr In $findReplace) {
                    $urlLivro = $urlLivro -replace $fr[0], $fr[1]
                }

                Write-Host "`t`t`t$nomeLivro"
                $requestL = Invoke-WebRequest $urlLivro
                If ($requestL.StatusCode -eq 200) {
                    $metadadosLivro = $requestL.ParsedHtml.scripts[1].text | ConvertFrom-Json
                    $urlCerta = ($metadadosLivro.'@graph' | Where-Object { $_.mainEntityOfPage }).mainEntityOfPage
                    If ($urlCerta -ne $urlLivro) {
                        Throw "Montei o link errado: $urlLivro => $urlCerta ($($biblia.nome) => $nomeLivro)"
                    }
                    $objL = [ordered]@{
                        nome = $nomeLivro
                        indice = $livro
                        url = $urlLivro
                        capitulos = [ordered]@{}
                    }
                    $result.grupos."$grupo".livros."$livro" = $objL

                    # Capítulos
                    $ulCapitulos = $requestL.ParsedHtml.body.getElementsByClassName("listChapter")[0]
                    $lisCapitulo = $ulCapitulos.getElementsByTagName("li")
                    ForEach ($liCapitulo In $lisCapitulo) {
                        $capitulo = $liCapitulo.innerText
                        $urlCapitulo = $liCapitulo.children[0].href
                        $requestC = Invoke-WebRequest $urlCapitulo
                        $h1 = $requestC.ParsedHtml.body.getElementsByTagName("h1")[0]
                        $titulo = $h1.innerText
                        $objC = [ordered]@{
                            nome = $titulo
                            numero = $capitulo
                            url = $urlCapitulo
                            versiculos = [ordered]@{}
                        }
                        If ($requestC.StatusCode -eq 200) {
                            Write-Host -NoNewline "`t`t`t`t$capitulo =>"

                            # Versículos
                            $entry = $requestC.ParsedHtml.body.getElementsByClassName("entry")[0]
                            $pVersiculos = $entry.getElementsByTagName("p")
                            ForEach ($pVersiculo In $pVersiculos) {
                                $versiculo = $pVersiculo.getAttribute("data-v").ToString()
                                If (-not $versiculo.Trim()) {
                                    $versiculo = [int]$pVersiculo.getElementsByTagName("strong")[0].innerText
                                }
                                $versiculo = [int]$versiculo
                                Write-Host -NoNewline " $versiculo"
                                $objV = [ordered]@{
                                    numero = $versiculo
                                }
                                If ($pVersiculo.getElementsByTagName("a").length -gt 0) {
                                    $objV.url = $pVersiculo.getElementsByTagName("a")[0].href
                                }
                                If ($pVersiculo.getElementsByTagName("span").length -gt 0) {
                                    If ($pVersiculo.getElementsByTagName("span")[0].innerHTML) {
                                        $objV.texto = $pVersiculo.getElementsByTagName("span")[0].innerHTML.Trim()
                                    } Else {
                                        $objV.texto = ($pVersiculo.childNodes | Where-Object { $_.nodeName -eq "#text" }).textContent.Trim()
                                    }
                                }
                                $objC.versiculos."$versiculo" = $objV
                            }
                            $notas = $entry.parentNode.nextSibling.nextSibling
                            $pNotas = $notas.getElementsByTagName("p")
                            ForEach ($pNota In $pNotas) {
                                $strong = $pNota.getElementsByTagName("strong")[0]
                                $versiculo = [int]$strong.innerText.Split(",")[1]
                                Write-Host -NoNewline " ($versiculo)"
                                $nota = $pNota.innerHTML.Replace($strong.outerHTML, "")
                                If ($objC.versiculos."$versiculo".nota) {
                                    Throw "Notas múltiplas!"
                                }
                                $objC.versiculos."$versiculo".nota = $nota.Trim()
                            }
                            $result.grupos."$grupo".livros."$livro".capitulos."$capitulo" = $objC
                            Write-Host "" # para quebrar a linha
                        }
                    }
                }
            }
        }
        $json = $result | ConvertTo-Json -Depth 100 -Compress
        $json | Out-File $jsonOutputFile
    } Finally {
        Stop-Transcript
    }
}
