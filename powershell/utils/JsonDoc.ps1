class JsonDoc_Elemento {
    hidden [string]$id
    hidden [string]$tipo
    hidden [System.Collections.Specialized.OrderedDictionary]$metadata

    static [JsonDoc_Elemento] fromJson([string]$json) {
        $obj = $json | ConvertFrom-Json -AsHashtable
        return $($obj.typeName -as [type])::fromObject($obj)
    }

    JsonDoc_Elemento(
        [string]$id,
        [string]$tipo
    ) {
        $this.id = $id
        $this.tipo = $tipo
        $this.metadata = [ordered]@{}
    }

    [string] getMetadata([string]$key) {
        return $this.metadata.$key
    }

    [void] removeMetadata([string]$key) {
        $this.metadata.Remove($key)
    }

    [void] setMetadata([string]$key, [string]$value) {
        $this.metadata.$key = $value
    }

    [string] toJson() {
        return $this.toOrderedDictionary() | ConvertTo-Json -Depth 100
    }
}

class JsonDoc_Estrutura: JsonDoc_Elemento {
    hidden [JsonDoc_Elemento[]]$conteudo

    static [JsonDoc_Estrutura] fromObject([Object]$obj) {
        [JsonDoc_Elemento]$elemento = $($obj.typeName -as [type])::new($obj.id, $obj.tipo)
        foreach ($conteudo in $obj.conteudo) {
            $elemento.addConteudo($($conteudo.typeName -as [type])::fromObject($conteudo))
        }
        foreach ($metadata in $obj.metadata) {
            foreach ($key in $metadata.Keys) {
                $elemento.setMetadata($key, $metadata.$key)
            }
        }
        return $elemento
    }

    JsonDoc_Estrutura(
        [string]$id,
        [string]$tipo
    ) : base($id, $tipo) {
        $this.conteudo = @()
    }

    [void] addConteudo([JsonDoc_Elemento]$conteudo) {
        $this.addConteudo($conteudo, $this.conteudo.Count)
    }

    [void] addConteudo([JsonDoc_Elemento]$conteudo, [int]$position) {
        if ($this.conteudo.Length) {
            if ($conteudo.GetType() -ne $this.conteudo[0].GetType()) {
                throw "Tipo inválido: $($conteudo.GetType().Name). Deveria ser $($this.conteudo[0].GetType().Name)."
            }
        }
        if ($this.conteudo | Where-Object -FilterScript { $_.id -eq $conteudo.id }) {
            throw "ID duplicado: $($conteudo.id)."
        }
        if ($position -eq $this.conteudo.Length) {
            $this.conteudo += $conteudo
        } else {
            $this.conteudo = @($this.conteudo[0..$position]) + @($conteudo) + @($this.conteudo[($position + 1)..$this.conteudo.Length])
        }
    }

    [void] addConteudoAfter([JsonDoc_Elemento]$conteudo, [JsonDoc_Elemento]$referencia) {
        $this.addConteudo($conteudo, $this.conteudo.IndexOf($referencia))
    }

    [JsonDoc_Elemento[]] getConteudo() {
        return $this.conteudo
    }

    [JsonDoc_Elemento] getConteudoPorId([string]$id) {
        return $this.conteudo | Where-Object -FilterScript { $_.id -eq $id }
    }

    hidden [System.Collections.Specialized.OrderedDictionary] toOrderedDictionary() {
        $hConteudo = @()
        foreach ($c in $this.conteudo) {
            $hConteudo += $c.toOrderedDictionary()
        }
        return [ordered]@{
            typeName = $this.GetType().Name
            id = $this.id
            tipo = $this.tipo
            conteudo = $hConteudo
            metadata = $this.metadata
        }
    }
}

class JsonDoc_Texto: JsonDoc_Elemento {
    hidden [JsonDoc_Texto_Conteudo[]]$conteudo

    static [JsonDoc_Texto] fromObject([Object]$obj) {
        [JsonDoc_Texto]$elemento = $($obj.typeName -as [type])::new($obj.id, $obj.tipo)
        foreach ($conteudo in $obj.conteudo) {
            $elemento.addConteudo($conteudo.tipo, $conteudo.texto)
        }
        foreach ($metadata in $obj.metadata) {
            foreach ($key in $metadata.Keys) {
                $elemento.setMetadata($key, $metadata.$key)
            }
        }
        return $elemento
    }

    JsonDoc_Texto(
        [string]$id,
        [string]$tipo
    ) : base($id, $tipo) {
        $this.conteudo = @()
    }

    [void] addConteudo($tipo, $texto) {
        $this.conteudo += [JsonDoc_Texto_Conteudo]::new($tipo, $texto)
    }

    hidden [System.Collections.Specialized.OrderedDictionary] toOrderedDictionary() {
        $hConteudo = @()
        foreach ($c in $this.conteudo) {
            $hConteudo += [ordered]@{
                tipo = $c.tipo
                texto = $c.texto
            }
        }
        return [ordered]@{
            typeName = $this.GetType().Name
            id = $this.id
            tipo = $this.tipo
            conteudo = $hConteudo
            metadata = $this.metadata
        }
    }
}

class JsonDoc_Texto_Conteudo {
    hidden [string]$tipo
    hidden [string]$texto

    JsonDoc_Texto_Conteudo(
        [string]$tipo,
        [string]$texto
    ) {
        $this.tipo = $tipo
        $this.texto = $texto
    }

    [void] setTexto($texto) {
        $this.texto = $texto
    }
}
