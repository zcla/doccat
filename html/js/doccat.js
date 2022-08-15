"use strict";

class Utils {
    static downloadString(str, fileName) {
        const downloader = document.createElement('a');
        downloader.style.display = 'none';
        downloader.href = 'data:attachment/text,' + encodeURIComponent(str);
        downloader.target = '_blank';
        downloader.download = fileName;
        downloader.click();
    }

    static getUrlParam(param) {
        return this.getUrlParams()[param];
    }

    static getUrlParams() {
        const paramArray = location.search.replace('?', '').split('&');
        const result = {};
        for (const param of paramArray) {
            const [key, value] = param.split('=');
            result[key] = value;
        }
        return result;
    }

    static loadHtml(arquivo, selector, callback) {
        $(selector).empty();
        $(selector).append('<div class="spinner-border" role="status">');
        if (!arquivo.match('/')) {
            $('<link href="css/' + arquivo.replace('.html', '') + '.css" rel="stylesheet">').appendTo("head");
        }
        $(selector).load(arquivo, function(response, status, xhr) {
            switch (status) {
                case 'success':
                    if (selector == '#referencia') {
                        $(selector).prepend($('<label class="form-label">').append('Referência'));
                    }
    
                    DocCat.refReplace(selector);
                    if (callback) {
                        callback();
                    }
                    break;
                    
                case 'error':
                    // TODO Fazer um script PowerShell pra identificar o que deveria existir, para distinguiar o que ainda não foi feito do que realmente não existe (se xhr.status for 404)
                    $(selector).empty();
                    $(selector)
                        .append($('<div class="alert alert-danger">')
                            .append($('<b>')
                                .append(xhr.status)
                                .append(' ')
                                .append(xhr.statusText))
                            .append(response));
                    break;
    
                default:
                    throw 'Não sei tratar "' + status + '"'; // TODO Tratar "notmodified", "nocontent", "timeout", "abort", or "parsererror"
            }
        });
    }
}

class DocCat {
    static inicializa() {
        // Trata parâmetros na URL
        const params = Utils.getUrlParams();
        if (params.pagina) {
            switch (params.pagina) {
                case 'catecismo':
                    $.getJSON("json/catecismo.json", function(data) {
                        Catecismo.json = data;
                    });
                    Catecismo.montaPagina(params);
                    break;
                case 'documento':
                    $.getJSON("json/documento.json", function(data) {
                        Documento.json = data;
                    });
                    Documento.montaPagina(params);
                    break;
                case 'tribos':
                    // Nada
                    break;
                default:
                    throw "Página desconhecida";
            }
        }
        Storage.updateMenu();
    }
    
    static refReplace(selector) {
        $('ref-biblia').each(function() {
            // TODO Fazer uma pesquisa no Google ou mandar pra algum site enquanto não tenho o texto.
            const replacement = this.innerHTML;
            $(this).replaceWith($('<span style="border: 1px dashed #00f !important; border-radius: 4px;">').append(replacement));
        });
    
        $('ref-cic').each(function() {
            let numero = $(this).attr('numero');
            numero = numero ? numero : this.innerText;
            let replacement = $('<a onclick="javascript:Catecismo.referencia(\'' + numero + '\');">').append(this.innerHTML);
            if (selector == '#grupo') { // Se o link vier da barra de grupo, colocar na estrutura do texto
                const grupo = Catecismo.cic2grupo(numero);
                replacement = $('<a href="?pagina=catecismo&grupo=' + grupo + '&cic=' + numero + '">').append(this.innerHTML);
            }
            $(this).replaceWith(replacement);
        });

        $('ref-doc').each(function() {
            const doc = $(this).attr('nome');
            const paragrafo = $(this).attr('paragrafo');
            let replacement = $(this);
            if (paragrafo) {
                // Se o link for para um parágrafo...
                if (selector == '#estrutura' || selector == '#textoNavegador') {
                    // ...vai para a página do item
                    let hrefReplacement = '?pagina=documento&nome=' + doc;
                    hrefReplacement += '&paragrafo=' + paragrafo;
                    replacement = $('<a href="' + hrefReplacement + '">').append(this.innerHTML);
                } else {
                    // ...coloca o conteúdo na área de referência
                    let hrefReplacement = '?pagina=documento&nome=' + doc;
                    hrefReplacement += '&paragrafo=' + paragrafo;
                    replacement = $('<a onclick="javascript:Documento.referencia(\'' + doc + '\', \'' + paragrafo + '\');">').append(this.innerHTML);
                }
            } else {
                // Se o link for para o documento, abre em uma outra aba
                replacement = $('<a href="?pagina=documento&nome=' + doc + '" target="_blank">').append(this.innerHTML);
            }
            $(this).replaceWith(replacement);
        });
    }
}

class Storage {
    static exportar() {
        const result = {};
        for (var key in localStorage){
            result[key] = localStorage[key];
        }
        Utils.downloadString(JSON.stringify(result), 'doccat.anotacoes.json'); // TODO Colocar data e hora no nome do arquivo.
    }

    static importar() {
        $('#storageUpload').removeClass('d-none');
    }

    static importarOnChange(evt) {
        $('#storageUpload').addClass('d-none');
        $('#storageUploadSpinner').removeClass('d-none');
        const file = $('#storageUpload input')[0].files[0];
        const reader = new FileReader();
        reader.onload = function(event) {
            const result = JSON.parse(event.target.result);
            for (var key in result){
                if (key == 'length') {
                    continue;
                }
                console.log(result[key]);
                Storage.setItem(key, result[key]);
            }
            $('#storageUploadSpinner').addClass('d-none');
            $('#storageUpload input').val(null);
            window.location.reload();
        }
        reader.readAsText(file);
    }

    static getItem(key) {
        try {
            return localStorage[key];
        } catch {
            return null;
        }
    }

    static setItem(key, val) {
        if (val) {
            localStorage[key] = val;
        } else {
            localStorage.removeItem(key);
        }
        Storage.updateMenu();
    }
    
    static updateMenu() {
        $($('#storageMenu a')[0]).text('Anotações (' + localStorage.length + ')');
    }
}

class Catecismo {
    static json = null;
    static #cic2grupo = null;
    static #cicEmOrdem = null;

    static anotacoesOnInput() {
        const key = 'catecismo.' + Utils.getUrlParam('cic');
        const val = $('#anotacoes textarea').val();
        Storage.setItem(key, val);
        $('#preview').html(marked.parse(val));
        DocCat.refReplace("#preview");
    }

    static cic2grupo(cic) {
        if (!this.#cic2grupo) {
            this.#cic2grupo = {};
            for (const grupo of this.json) {
                for (const cic of grupo.cic) {
                    this.#cic2grupo[cic] = grupo.grupo;
                }
            }
        }
        return this.#cic2grupo[cic];
    }

    static cicAnterior(cic) {
        const pos = this.cicPosicao(cic);
        if (pos > 0) {
            return this.#cicEmOrdem[pos - 1];
        }
        return null;
    }

    static cicPosicao(cic) {
        if (!this.#cicEmOrdem) {
            this.#cicEmOrdem = [];
            for (const grupo of this.json) {
                for (const cic of grupo.cic) {
                    this.#cicEmOrdem.push(cic);
                }
            }
        }
        return this.#cicEmOrdem.indexOf(cic);
    }

    static cicPosterior(cic) {
        const pos = this.cicPosicao(cic);
        if (pos < this.#cicEmOrdem.length) {
            return this.#cicEmOrdem[pos + 1];
        }
        return null;
    }

    static montaPagina(params) {
        Utils.loadHtml('catecismo.html', '#doccat', function() {
            let estruturaClasses = [ 'col-12' ];
            let grupoTextoReferenciaClasses = [ 'd-none' ];
            let anotacoesPreviewClasses = [ 'd-none' ];
            if (params.grupo) {
                estruturaClasses = [ 'col-6' ];
                grupoTextoReferenciaClasses = [ 'col-6' ];
                $('#estrutura a[href="?pagina=catecismo&grupo=' + params.grupo + '"]').parent().parent().addClass('selecionado');
                if (params.cic) {
                    estruturaClasses = [ 'col-2', 'tresColunas' ];
                    grupoTextoReferenciaClasses = [ 'col-6' ];
                    anotacoesPreviewClasses = [ 'col-4' ];
                }
                Utils.loadHtml('catecismo/' + params.grupo, '#grupo', function() { // TODO Está carregando duas vezes o grupo, sei lá por quê.
                    if (params.cic) {
                        $('#grupo a[href^="?pagina=catecismo"][href$="&cic=' + params.cic + '"]').parent().parent().addClass('selecionado');
                        Utils.loadHtml('catecismo/' + params.grupo + '/cic_' + params.cic + '.html', '#texto', function() {
                            const navegador = $('<div class="navegador">');
                            const anterior = Catecismo.cicAnterior(params.cic);
                            if (anterior != null) {
                                navegador.append($('<ref-cic numero="' + anterior + '">&#129092;</ref-cic>'));
                            }
                            const posterior = Catecismo.cicPosterior(params.cic);
                            if (posterior != null) {
                                navegador.append($('<ref-cic numero="' + posterior + '">&#129094;</ref-cic>'));
                            }
                            $('#texto').append(navegador);
                            DocCat.refReplace("#grupo");
                            $('#anotacoes textarea').val(Storage.getItem('catecismo.' + params.cic));
                            Catecismo.anotacoesOnInput();
                        });
                    }
                });
            }
            $('#estrutura').removeClass();
            estruturaClasses.forEach(function(className) { $('#estrutura').addClass(className) });
            $('#grupoTextoReferencia').removeClass();
            grupoTextoReferenciaClasses.forEach(function(className) { $('#grupoTextoReferencia').addClass(className) });
            $('#anotacoesPreview').removeClass();
            anotacoesPreviewClasses.forEach(function(className) { $('#anotacoesPreview').addClass(className) });
        });
    }

    // Mostra o texto como referência
    static referencia(referencia) {
        const spl = referencia.split('-');
        switch (spl.length) {
            case 1: {
                const grupo = Catecismo.cic2grupo(referencia);
                Utils.loadHtml('catecismo/' + grupo + '/cic_' + referencia + '.html', '#referencia');
                break;
            }

            case 2:
                $('#referencia').empty();
                let status = 'procurando';
                for (const grupo of this.json) {
                    for (const cic of grupo.cic) {
                        if (cic == spl[0]) {
                            status = 'achei';
                        }
                        if (status == 'achei') {
                            $('#referencia').append('<div id="referencia_' + cic + '">');
                            Utils.loadHtml('catecismo/' + grupo.grupo + '/cic_' + cic + '.html', '#referencia_' + cic);
                        }
                        if (cic == spl[1]) {
                            status = 'acabou';
                            break;
                        }
                    }
                    if (status == 'acabou') {
                        break;
                    }
                }
                if (status == 'procurando') {
                    $('#referencia')
                    .append($('<div class="alert alert-danger">')
                        .append("Não encontrado"));
                }
                break;

            default:
                throw "Referência inválida."
        }
    }
}

class Documento {
    static json = null;
    static #paragrafoEmOrdem = null;

    static anotacoesOnInput() {
        const urlParams = Utils.getUrlParams();
        const key = 'documento.' + urlParams.nome + '.' + urlParams.paragrafo;
        const val = $('#anotacoes textarea').val();
        Storage.setItem(key, val);
        $('#preview').html(marked.parse(val));
        DocCat.refReplace("#preview");
    }

    static montaPagina(params) {
        Utils.loadHtml('documento.html', '#doccat', function() {
            let estruturaClasses = [ 'col-12' ];
            let textoReferenciaClasses = [ 'd-none' ];
            let anotacoesPreviewClasses = [ 'd-none' ];
            if (params.nome) {
                const a = $('#documentoLista a[href*="?pagina=' + params.pagina + '&nome=' + params.nome + '"]');
                if (a.length) {
                    const tds = a.parent().parent()[0].children;
                    $('#documentoNome').append(tds[1].children[0].innerText);
                    $('#documentoTipo').append(tds[1].children[1].innerText);
                    $('#documentoAutor').append(tds[2].innerText);
                    $('#documentoData').append(tds[0].innerText);
                    Utils.loadHtml('documento/' + params.nome, '#estrutura', function() { // TODO Está carregando duas vezes o documento, sei lá por quê.
                        if (params.paragrafo) {
                            $('#estrutura a[href^="?pagina=documento&nome=' + params.nome + '"][href$="&paragrafo=' + params.paragrafo + '"]').parent().parent().addClass('selecionado');
                            Utils.loadHtml('documento/' + params.nome + '/' + params.paragrafo + '.html', '#texto', function() {
                                const navegador = $('<div id="textoNavegador" class="navegador">');
                                const anterior = Documento.paragrafoAnterior(params.paragrafo);
                                if (anterior != null) {
                                    navegador.append($('<ref-doc nome="' + params.nome + '" paragrafo="' + anterior + '">&#129092;</ref-paragrafo>'));
                                }
                                const posterior = Documento.paragrafoPosterior(params.paragrafo);
                                if (posterior != null) {
                                    navegador.append($('<ref-doc nome="' + params.nome + '" paragrafo="' + posterior + '">&#129094;</ref-paragrafo>'));
                                }
                                $('#texto').append(navegador);
                                DocCat.refReplace("#textoNavegador");
                                $('#anotacoes textarea').val(Storage.getItem('documento.' + params.nome + '.' + params.paragrafo));
                                Documento.anotacoesOnInput();
                            });
                        }
                    });
                    if (params.paragrafo) {
                        estruturaClasses = [ 'col-3', 'tresColunas' ];
                        textoReferenciaClasses = [ 'col-5' ];
                        anotacoesPreviewClasses = [ 'col-4' ];
                        $('#estrutura a[href="?pagina=documento&nome=' + params.nome + '"]').parent().parent().addClass('selecionado');
                    }
                } else {
                    if (Documento.json[params.nome]) {
                        Utils.loadHtml('documento/' + params.nome, '#estrutura');
                    } else {
                        $('#documento').append($('<div class="alert alert-danger">').append('Documento "' + params.nome + '" não encontrado.'));
                    }
                }
                $('#documentoLista').empty();
            }
            $('#estrutura').removeClass();
            estruturaClasses.forEach(function(className) { $('#estrutura').addClass(className) });
            $('#textoReferencia').removeClass();
            textoReferenciaClasses.forEach(function(className) { $('#textoReferencia').addClass(className) });
            $('#anotacoesPreview').removeClass();
            anotacoesPreviewClasses.forEach(function(className) { $('#anotacoesPreview').addClass(className) });
        });
    }

    static paragrafoAnterior(paragrafo) {
        const pos = this.paragrafoPosicao(paragrafo);
        if (pos > 0) {
            return this.#paragrafoEmOrdem[pos - 1];
        }
        return null;
    }

    static paragrafoPosicao(paragrafo) {
        // TODO Precisa mesmo disso aqui?
        if (!this.#paragrafoEmOrdem) {
            this.#paragrafoEmOrdem = [];
            for (const paragrafo of Documento.json[Utils.getUrlParam('nome')].paragrafo) {
                this.#paragrafoEmOrdem.push(paragrafo);
            }
        }
        return this.#paragrafoEmOrdem.indexOf(paragrafo);
    }

    static paragrafoPosterior(paragrafo) {
        const pos = this.paragrafoPosicao(paragrafo);
        if (pos < this.#paragrafoEmOrdem.length) {
            return this.#paragrafoEmOrdem[pos + 1];
        }
        return null;
    }

    // Mostra o texto como referência
    static referencia(documento, numero) {
        if (this.json[documento]) {
            const spl = numero.split('-');
            switch (spl.length) {
                case 1: {
                    Utils.loadHtml('documento/' + documento + '/' + numero + '.html', '#referencia');
                    break;
                }

                case 2:
                    throw "Tratar referência de múltiplos números"
                    break;

                default:
                    throw "Referência inválida."
            }
        } else {
            $('#referencia').empty();
            $('#referencia')
                .append($('<div class="alert alert-danger">')
                    .append("Documento não encontrado"));
        }
    }
}

$(document).ready(function () {
    DocCat.inicializa();
});
