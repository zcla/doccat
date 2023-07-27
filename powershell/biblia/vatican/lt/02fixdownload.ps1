$scriptPath = Get-Item ($MyInvocation.MyCommand.Path)
Set-Location $scriptPath.PSParentPath
$fileName = ".\$($scriptPath.Name.split('.')[0]).json"

Write-Host "Inicializando" -ForegroundColor Cyan -NoNewline
$result = Get-Content -Path .\01download.json | ConvertFrom-Json -AsHashtable
Write-Host " ok" -ForegroundColor Green


Write-Host "Consertando" -ForegroundColor Cyan -NoNewline
if (Test-Path $fileName) {
    Write-Host " já feito" -ForegroundColor Green
} else {
    Write-Host " fazendo..." -ForegroundColor Yellow

    Write-Host "numeri 1" -ForegroundColor Cyan -NoNewline
    Write-Host " $($result.livros.numeri.texto.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # Falta o número do versículo em 1,1
    $result.livros.numeri.texto = $result.livros.numeri.texto.Replace('&nbsp;Locutusque', '1 Locutusque')
    Write-Host " $($result.livros.numeri.texto.Length)" -ForegroundColor Green

    Write-Host "iudicum 18/19" -ForegroundColor Cyan -NoNewline
    Write-Host " $($result.livros.iudicum.texto.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # O resto do texto de 18,31 aparece antes de 19,1
    $result.livros.iudicum.texto = $result.livros.iudicum.texto.Replace('<br /> </p> <p> <b><font color="#663300"><a name="19">19</a></font></b> &nbsp;<br /> In diebus illis non erat rex in Israel. <br />', '<br /> In diebus illis non erat rex in Israel. <br /> </p> <p> <b><font color="#663300"><a name="19">19</a></font></b> &nbsp;<br />')
    Write-Host " $($result.livros.iudicum.texto.Length)" -ForegroundColor Green

    Write-Host "psalmorum" -ForegroundColor Cyan -NoNewline
    Write-Host " $($result.livros.psalmorum.texto.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # Âncoras para grupos de salmos
    $result.livros.psalmorum.texto = $result.livros.psalmorum.texto -replace '<a name="LIBER [^"]*"> ?(<font size="4">)?[^<]*(<\/font>)?<\/a>', ''
    # Tira o "PSALMUS" das âncoras
    $result.livros.psalmorum.texto = $result.livros.psalmorum.texto -replace '(<a name=")PSALMUS (\d+">) ?PSALMUS (\d+<\/a>)', '$1$2$3'
    Write-Host " $($result.livros.psalmorum.texto.Length)" -ForegroundColor Green

    Write-Host "ecclesiasticus Prólogo" -ForegroundColor Cyan -NoNewline
    Write-Host " $($result.livros.ecclesiasticus.texto.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # Adiciona o prólogo como se fosse um capítulo
    $result.livros.ecclesiasticus.texto = $result.livros.ecclesiasticus.texto.Replace('Cum multa nobis', '<b><font color="#663300"><a name="Prólogo">Prólogo</a></font></b>&nbsp;<br /> 0 Cum multa nobis')
    Write-Host " $($result.livros.ecclesiasticus.texto.Length)" -ForegroundColor Green

    Write-Host "ecclesiasticus 1" -ForegroundColor Cyan -NoNewline
    Write-Host " $($result.livros.ecclesiasticus.texto.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # Tem um parêntese a mais em 1,20
    $result.livros.ecclesiasticus.texto = $result.livros.ecclesiasticus.texto.Replace('<br /> (20', '<br /> 20')
    Write-Host " $($result.livros.ecclesiasticus.texto.Length)" -ForegroundColor Green

    Write-Host "baruch 6" -ForegroundColor Cyan -NoNewline
    Write-Host " $($result.livros.baruch.texto.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # Tem um texto sem versículo antes de 6,1
    $result.livros.baruch.texto = $result.livros.baruch.texto.Replace('<br /> Exemplum epistulae,', '<br />0 Exemplum epistulae,')
    Write-Host " $($result.livros.baruch.texto.Length)" -ForegroundColor Green

    Write-Host "ezechielis 31" -ForegroundColor Cyan -NoNewline
    Write-Host " $($result.livros.'ezechielis'.texto.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # O versículo está colado no texto em 31,2
    $result.livros.'ezechielis'.texto = $result.livros.'ezechielis'.texto.Replace('2&#x201c; Fili hominis', '2 &#x201c; Fili hominis')
    Write-Host " $($result.livros.'ezechielis'.texto.Length)" -ForegroundColor Green

    Write-Host "actus-apostolorum 6" -ForegroundColor Cyan -NoNewline
    Write-Host " $($result.livros.'actus-apostolorum'.texto.Length)" -ForegroundColor Red -NoNewline
    Write-Host " =>" -ForegroundColor Cyan -NoNewline
    # O versículo está colado no texto em 17,1
    $result.livros.'actus-apostolorum'.texto = $result.livros.'actus-apostolorum'.texto.Replace('1Cum', '1 Cum')
    Write-Host " $($result.livros.'actus-apostolorum'.texto.Length)" -ForegroundColor Green

    Write-Host "Gravando" -ForegroundColor Cyan -NoNewline
    $result | ConvertTo-Json -Depth 100 | Out-File (New-Item $fileName -Force)
    Write-Host " ok" -ForegroundColor Green
}

Write-Host "Fim" -ForegroundColor Cyan
