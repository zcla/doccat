$scriptPath = Get-Item ($MyInvocation.MyCommand.Path)
Set-Location $scriptPath.PSParentPath
$fileName = ".\$($scriptPath.Name.split('.')[0]).json"

Write-Host "Inicializando" -ForegroundColor Cyan -NoNewline
$biblia = Get-Content -Path ..\..\biblia.json | ConvertFrom-Json -AsHashtable
$config = Get-Content -Path .\config.json | ConvertFrom-Json -AsHashtable
$dados = Get-Content -Path .\04fixjson.json | ConvertFrom-Json -AsHashtable
Write-Host " ok" -ForegroundColor Green

Write-Host "Padronizando" -ForegroundColor Cyan -NoNewline
if (Test-Path $fileName) {
	Write-Host " já feito" -ForegroundColor Green
} else {
    Write-Host " fazendo..." -ForegroundColor Yellow

    $result = [ordered]@{
        livros = [ordered]@{}
        ordemLivros = $dados.ordemLivros
    }
    foreach ($livro in $biblia.livros) {
        $sigla = $livro.sigla
        Write-Host "  $sigla" -ForegroundColor Cyan -NoNewline
        $dadosSigla = $config.'mapa-livro'.Keys | Where-Object -FilterScript { $config.'mapa-livro'.$_ -eq $sigla }
        $dadosLivro = $dados.livros.$dadosSigla
        if ($dadosLivro) {
            $result.livros.$sigla = [ordered]@{
                dataHora = $dadosLivro.dataHora
                fonte = $dadosLivro.fonte
                capitulos = [ordered]@{}
            }
            foreach ($capitulo in $livro.capitulos) {
                $numCapitulo = $capitulo.numero
                Write-Host " $numCapitulo" -ForegroundColor Cyan -NoNewline
                if (-not $numCapitulo) {
                    $numCapitulo = ""
                }
                $dadosCapitulo = $dadosLivro.capitulos.$numCapitulo
                if ($dadosCapitulo) {
                    $versiculos = $capitulo.versiculos
                    if ($versiculos) {
                        switch ($versiculos.GetType().Name) {
                            'Int64' {
                                $numVersiculos = $versiculos
                                $versiculos = @()
                                for ($v = 1; $v -le $numVersiculos; $v++) {
                                    $versiculos += "$v"
                                }
                            }
                            'Object[]' {
                                # Já é uma lista; fica como está.
                            }
                            default {
                                throw "???"
                            }
                        }
                        Write-Host " ($($versiculos.Length))" -ForegroundColor Green -NoNewline
                    } else {
                        Write-Host " (-)" -ForegroundColor Green -NoNewline
                    }
                    $result.livros.$sigla.capitulos.$numCapitulo = [ordered]@{
                        # numero = $numCapitulo
                        fonte = $dadosCapitulo.fonte
                        versiculos = [ordered]@{}
                    }
                    foreach ($versiculo in $versiculos) {
                        $dadosVersiculo = $dadosCapitulo.versiculos.$versiculo
                        if ($dadosVersiculo) {
                            $result.livros.$sigla.capitulos.$numCapitulo.versiculos.$versiculo = $dadosVersiculo
                        } else {
                            Write-Host " [versículo $versiculo não encontrado]" -ForegroundColor Red -NoNewline
                        }
                    }
                } else {
                    Write-Host " não encontrado" -ForegroundColor Red -NoNewline
                }
            }
        } else {
            Write-Host " não encontrado" -ForegroundColor Red -NoNewline
        }
        Write-Host ""
    }

    Write-Host "Gravando" -ForegroundColor Cyan -NoNewline
    $result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
    Write-Host " ok" -ForegroundColor Green
}

Write-Host "Fim" -ForegroundColor Cyan
