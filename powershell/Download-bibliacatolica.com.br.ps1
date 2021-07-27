Clear-Host

Function LogFileName($str) {
    $item = Get-Item $PSCommandPath
    $result = "$($item.Directory.FullName)\..\log\$($item.Name)($str).log"
    return $result
}

Function JsonFileName($str) {
    $item = Get-Item $PSCommandPath
    $result = "$($item.Directory.FullName)\..\download\bibliacatolica.com.br.$str.json"
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
        # $json = $json.Replace("\u0026", "&").Replace("\u0027", "'").Replace("\u003c", "<").Replace("\u003e", ">").Replace("&shy;", "")
        $json | Out-File $jsonOutputFile
    } Finally {
        Stop-Transcript
    }
}

<#
param (
    [string]$url = "https://www.bibliacatolica.com.br/biblia-ave-maria/"
)
#>

<#
Clear-Host
$request = Invoke-WebRequest "https://www.bibliacatolica.com.br/"
$biblias = @()
If ($request.StatusCode -eq 200) {
    $ulBiblias = $request.ParsedHtml.body.childNodes[3].childNodes[1].childNodes[5].childNodes[3]
    ForEach ($liBiblia In $ulBiblias.children) {
        $href = $liBiblia.children[0].href
        $nome = $liBiblia.children[0].innerText.Trim()
        $lang = $liBiblia.children[0].children[0].className.Split(' ')[1].Split('-')[1]
        $biblias += [ordered]@{
            href = $href
            nome = $nome
            lang = $lang
        }
    }
}
$maxLength = 0
ForEach ($biblia In $biblias) {
    if ($biblia.href.length -gt $maxLength) {
        $maxLength = $biblia.href.length
    }
}
ForEach ($biblia In $biblias) {
    Write-Host ".\Get-bibliacatolica.com.br.ps1 $($biblia.href.PadRight($maxLength))   # $($biblia.lang)   $($biblia.nome)"
}

.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/biblia-ave-maria/genesis/1/                                  # pt   Bíblia Ave Maria
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/la-biblia-de-jerusalen/genesis/1/                            # es   La Biblia de Jerusalén
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/el-libro-del-pueblo-de-dios/genesis/1/                       # es   El Libro del Pueblo de Dios
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/la-santa-biblia/genesis/1/                                   # es   La Santa Biblia
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/biblia-latinoamericana/genesis/1/                            # ca   Biblia Latinoamericana
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/la-sacra-bibbia/genesi/1/                                    # it   La Sacra Bibbia
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/la-bibbia/genesi/1/                                          # it   La Bibbia
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/biblia-de-jerusalem/genese/1/                                # fr   Bíblia de Jerusalem
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/la-bible-des-communautes-chretiennes/genese/1/               # fr   La Bible Des Communautés Chrétiennes
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/la-sainte-bible-augustin-crampon-1923/genese/1/              # fr   La Sainte Bible (Augustin Crampon 1923)
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/la-sainte-bible-traduction-catholique-de-fillion/genese/1/   # fr   La Sainte Bible (Traduction catholique de Fillion)
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/the-new-american-bible/genesis/1/                            # en   The New American Bible
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/douay-rheims-version/genesis/1/                              # en   Douay-Rheims Version
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/king-james-version/genesis/1/                                # en   King James Version
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/revised-standard-version/genesis/1/                          # en   Revised Standard Version
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/christian-community-bible/genesis/1/                         # en   Christian Community Bible
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/new-jerusalem-bible/genesis/1/                               # en   New Jerusalem Bible
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/catholic-public-domain-version/genesis/1/                    # en   Catholic Public Domain Version
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/vulgata-latina/liber-genesis/1/                              # la   Vulgata Latina
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/neo-vulgata-latina/liber-genesis/1/                          # la   Neo Vulgata Latina
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/septuaginta/genesis/1/                                       # el   Septuaginta + NT
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/septuaginta-transliterada/genesis/1/                         # el   Septuaginta + NT (transliterada)
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/die-bibel/das-buch-genesis/1/                                # de   Die Bibel
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/biblia-tysiaclecia/ksiega-rodzaju/1/                         # pl   Biblia Tysiąclecia
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/biblija-hrvatski/knjiga-postanka/1/                          # hr   Biblija Hrvatski
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/katolikus-biblia/teremtes-konyve/1/                          # hu   Katolikus Biblia
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/raamattu-ja-biblia/1-mooseksen-kirja/1/                      # fi   Raamattu ja Biblia
.\Get-bibliacatolica.com.br.ps1 https://www.bibliacatolica.com.br/biblia-romano-catolica/cartea-genezei/1/                     # ro   Biblia Romano-Catolică
#>

<#
Clear-Host

$result = [ordered]@{
    nome = "?"
    url = $url
    grupos = [ordered]@{}
}

$request = Invoke-WebRequest $url
If ($request.StatusCode -eq 200) {
    $selectBiblias = $request.ParsedHtml.body.getElementsByClassName("biblias")[0]
    $result.nome = $selectBiblias.getElementsByTagName("option")[$selectBiblias.selectedIndex].text
    Start-Transcript "$PSCommandPath($($result.nome)).log" -Force
    Try {
        Write-Host "$($result.nome)"

        While ($request) {
            If ($request.StatusCode -eq 200) {
                $selectLivros = $request.ParsedHtml.body.getElementsByClassName("livros")[0]
                $optionLivro = $selectLivros.getElementsByTagName("option")[$selectLivros.selectedIndex]
                $grupo = $optionLivro.parentNode.label
                If (-not ($result.grupos."$grupo")) {
                    Write-Host "  $grupo"
                    $result.grupos."$grupo" = [ordered]@{
                        nome = $grupo
                        livros = [ordered]@{}
                    }
                }
                $livro = $optionLivro.value
                $h1 = $request.ParsedHtml.body.getElementsByTagName("h1")[0]
                $titulo = $h1.innerText
                $spl = $titulo.Split(",")
                $nomeLivro = $spl[0]
                If (-not ($result.grupos."$grupo".livros."$livro")) {
                    Write-Host "    $nomeLivro"
                    $objL = [ordered]@{
                        nome = $nomeLivro
                        indice = $livro
                        capitulos = [ordered]@{}
                    }
                    $result.grupos."$grupo".livros."$livro" = $objL
                }
                $capitulo = [int]$spl[1]
                If ($result.grupos."$grupo".livros."$livro".capitulos."$capitulo") {
                    $request = $null # se começou a repetir é porque acabou
                } Else {
                    Write-Host -NoNewline "      $capitulo`:"
                    $objC = [ordered]@{
                        nome = $titulo
                        numero = $capitulo
                        url = $request.BaseResponse.ResponseUri
                        versiculos = [ordered]@{}
                    }
                    $entry = $request.ParsedHtml.body.getElementsByClassName("entry")[0]
                    $pVersiculos = $entry.getElementsByTagName("p")
                    ForEach ($pVersiculo In $pVersiculos) {
                        $versiculo = [int]$pVersiculo.getAttribute("data-v")
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
                    # próximo
                    Write-Host "" # para quebrar a linha
                    $pager = $request.ParsedHtml.body.getElementsByClassName("pager")[0]
                    $proximoCapitulo = $pager.getElementsByTagName("li")[2]
                    $request = Invoke-WebRequest $proximoCapitulo.children[0].href
                }
            } Else {
                Throw "Erro $($request.StatusCode) ao buscar dados em $url"
                $request = $null
            }
        }
    } Finally {
        Stop-Transcript
    }
} Else {
    Throw "Erro $($request.StatusCode) ao buscar dados em $url"
}

$json = $result | ConvertTo-Json -Depth 100 -Compress
# $json = $json.Replace("\u0026", "&").Replace("\u0027", "'").Replace("\u003c", "<").Replace("\u003e", ">").Replace("&shy;", "")
$json | Out-File "..\..\json\bibliacatolica.com.br.$($result.nome).json"

Return $result
#>
