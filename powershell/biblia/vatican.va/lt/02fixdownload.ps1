$scriptPath = Get-Item ($MyInvocation.MyCommand.Path)
Set-Location $scriptPath.PSParentPath
$fileName = ".\$($scriptPath.Name.split('.')[0]).json"

Write-Host "Inicializando" -ForegroundColor Cyan -NoNewline
. ..\..\..\utils\JsonDoc.ps1
$result = [JsonDoc_Elemento]::fromJson((Get-Content -Path .\01download.json))
Write-Host " ok" -ForegroundColor Green


Write-Host "Consertando" -ForegroundColor Cyan -NoNewline
if (Test-Path $fileName) {
    Write-Host " já feito" -ForegroundColor Green
} else {
    Write-Host " fazendo..." -ForegroundColor Yellow

    Write-Host "numeri 1" -ForegroundColor Cyan -NoNewline
    $livro = $result.getConteudoPorId('numeri')
    $html = $livro.getMetadata('html')
    Write-Host " $($html.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # Falta o número do versículo em 1,1
    $html = $html.Replace('&nbsp;Locutusque', '1 Locutusque')
    $livro.setMetadata('html', $html)
    Write-Host " $($html.Length)" -ForegroundColor Green

    Write-Host "iudicum 18/19" -ForegroundColor Cyan -NoNewline
    $livro = $result.getConteudoPorId('iudicum')
    $html = $livro.getMetadata('html')
    Write-Host " $($html.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # O resto do texto de 18,31 aparece antes de 19,1
    $html = $html.Replace('<br /> </p> <p> <b><font color="#663300"><a name="19">19</a></font></b> &nbsp;<br /> In diebus illis non erat rex in Israel. <br />', '<br /> In diebus illis non erat rex in Israel. <br /> </p> <p> <b><font color="#663300"><a name="19">19</a></font></b> &nbsp;<br />')
    $livro.setMetadata('html', $html)
    Write-Host " $($html.Length)" -ForegroundColor Green

    Write-Host "psalmorum" -ForegroundColor Cyan -NoNewline
    $livro = $result.getConteudoPorId('psalmorum')
    $html = $livro.getMetadata('html')
    Write-Host " $($html.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # Âncoras para grupos de salmos
    $html = $html -replace '<a name="LIBER [^"]*"> ?(<font size="4">)?[^<]*(<\/font>)?<\/a>', ''
    Write-Host " $($html.Length)" -ForegroundColor Yellow -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # Tira o "PSALMUS" das âncoras
    $html = $html -replace '(<a name=")PSALMUS (\d+">) ?PSALMUS (\d+<\/a>)', '$1$2$3'
    $livro.setMetadata('html', $html)
    Write-Host " $($html.Length)" -ForegroundColor Green

    Write-Host "ecclesiasticus" -ForegroundColor Cyan -NoNewline
    $livro = $result.getConteudoPorId('ecclesiasticus')
    $html = $livro.getMetadata('html')
    Write-Host " $($html.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # Adiciona o prólogo como se fosse um capítulo
    $html = $html.Replace('Cum multa nobis', '<b><font color="#663300"><a name="Prólogo">Prólogo</a></font></b>&nbsp;<br /> 0 Cum multa nobis')
    Write-Host " $($html.Length)" -ForegroundColor Yellow -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # Tem um parêntese a mais em 1,20
    $html = $html.Replace('<br /> (20', '<br /> 20')
    $livro.setMetadata('html', $html)
    Write-Host " $($html.Length)" -ForegroundColor Green

    Write-Host "baruch 6" -ForegroundColor Cyan -NoNewline
    $livro = $result.getConteudoPorId('baruch')
    $html = $livro.getMetadata('html')
    Write-Host " $($html.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # Tem um texto sem versículo antes de 6,1
    $html = $html.Replace('<br /> Exemplum epistulae,', '<br />0 Exemplum epistulae,')
    $livro.setMetadata('html', $html)
    Write-Host " $($html.Length)" -ForegroundColor Green

    Write-Host "ezechielis 31" -ForegroundColor Cyan -NoNewline
    $livro = $result.getConteudoPorId('ezechielis')
    $html = $livro.getMetadata('html')
    Write-Host " $($html.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # O versículo está colado no texto em 31,2
    $html = $html.Replace('2&#x201c; Fili hominis', '2 &#x201c; Fili hominis')
    $livro.setMetadata('html', $html)
    Write-Host " $($html.Length)" -ForegroundColor Green

    Write-Host "actus-apostolorum 6" -ForegroundColor Cyan -NoNewline
    $livro = $result.getConteudoPorId('actus-apostolorum')
    $html = $livro.getMetadata('html')
    Write-Host " $($html.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # O versículo está colado no texto em 17,1
    $html = $html.Replace('1Cum', '1 Cum')
    $livro.setMetadata('html', $html)
    Write-Host " $($html.Length)" -ForegroundColor Green

    Write-Host "Gravando" -ForegroundColor Cyan -NoNewline
    $result.toJson() | Out-File (New-Item $fileName -Force)
    Write-Host " ok" -ForegroundColor Green
}

Write-Host "Fim" -ForegroundColor Cyan
