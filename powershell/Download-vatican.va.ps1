Function BibliaLatim($urls) {
    Write-Host "Biblia"
    $result = [ordered]@{}
    ForEach ($url In $urls) {
        Write-Host "  $url"
        $iwr = Invoke-WebRequest $url
        $urlsLivros = $iwr.Links | Where-Object { $_.href -match '^nova-vulgata_(v|n)t_' }
        ForEach ($urlLivro In $urlsLivros) {
            $livro = $urlLivro.href -replace '^nova-vulgata_(v|n)t_(.*)_lt.html', '$2'
            Write-Host "    $livro" -NoNewline
            $iwrLivro = Invoke-WebRequest "$($url.substring(0, $url.LastIndexOf('/')))/$($urlLivro.href)"
            $result.$livro = "$($iwrLivro.Content)"
            Write-Host " $($result.$livro.Length)"
        }
    }
    Return $result
}

$prjPath = ((Get-Item $MyInvocation.MyCommand.Path).Directory.Parent.FullName)

$config = Get-Content -Path "$prjPath\config\config.json" | ConvertFrom-Json

BibliaLatim $config.biblia.'vatican.va.Biblia.lt'.urls | ConvertTo-Json -Depth 100 | Out-File "$prjPath\download\vatican.va.Biblia.lt.json"
