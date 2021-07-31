Set-Location (Get-Item $MyInvocation.MyCommand.Path).Directory.FullName

Clear-Host

$apiVersion = "v1"

Function GeraAPI($objeto, $pasta) {
    # Remove pasta, se houver
    If (Test-Path $pasta) {
        Remove-Item $pasta -Recurse -Force
    }
    # Cria pasta
    $pasta = New-Item -Path $pasta -ItemType Directory

    # Processa itens
    $keys = $objeto.Keys
    ForEach ($key In $keys) {
        $objetoFilho = $objeto.$key
        $caminhoFilho = "$($pasta.FullName)\$key"
        If ($key.EndsWith('.json')) {
            $objetoFilho | ConvertTo-Json | Out-File $caminhoFilho
        } Else {
            GeraAPI $objetoFilho (New-Item $caminhoFilho)
        }
    }
}

Start-Transcript ("..\log\$((Get-Item $MyInvocation.MyCommand.Path).Name).log") -Force
Try {
    # Inicialização
    $api = @{
        "$apiVersion" = @{
            biblia = @{
            }
        }
    }

    Write-Host "Configuração"
    $config = Get-Content "..\config\config.json" | ConvertFrom-Json

    Write-Host "  biblia"
    Write-Host "    livro"
    $apiLivro = @{
        "index.json" = @()
    }
    ForEach ($livro In $config.biblia.livro) {
        $id = $livro.sigla
        $objLivro = [ordered]@{
            id = $id
			sigla = $livro.sigla
			nomeCurto = $livro.nomeCurto
			nomeLongo = $livro.nomeLongo
        }
        $apiLivro."index.json" += $objLivro
        $apiLivro.$id = [ordered]@{
            "index.json" = $objLivro
        }
    }
    $api.$apiVersion.biblia.livro = $apiLivro

    Write-Host "Bíblias"
    $versaoIndex = @()

    Write-Host "  bibliacatolica.com.br"
    $fonte = "bibliacatolica.com.br"
    $json = Get-Content "..\download\$fonte.json" | ConvertFrom-Json
    $apiVersao = @{
        "index.json" = @()
    }
    ForEach ($biblia In $json) {
        Write-Host "    $($biblia.nome)"
        $id = "$($fonte)_$($biblia.nome)"
        $apiVersao."index.json" += [ordered]@{
            id = $id
            nome = $biblia.nome
            fonte = $fonte
            idioma = $biblia.lang
            url = $biblia.url
        }
        $apiVersao.$id = @()

        $arqBiblia = "..\download\$fonte.$($biblia.nome).json"
        $jsonBiblia = Get-Content $arqBiblia | ConvertFrom-Json
        ForEach ($grupoProp In ($jsonBiblia.grupos | Get-Member -MemberType NoteProperty)) {
            $grupo = $jsonBiblia.grupos."$($grupoProp.Name)"
            Write-Host "      $($grupo.nome)"
            ForEach ($livroProp In ($grupo.livros | Get-Member -MemberType NoteProperty)) {
                $livro = $grupo.livros."$($livroProp.Name)"
                Write-Host "        $($livro.nome)"
            }
        }
    }

    # Bíblias - fim
    $api.$apiVersion.biblia.versao = $apiVersao

    # Geração dos arquivos da API
    $pasta = Get-Item("..\api")
    GeraAPI $api $pasta
} Finally {
    Stop-Transcript
}
