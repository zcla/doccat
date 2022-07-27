"use strict";

class Utils {
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
        $.getJSON("json/catecismo.json", function(data) {
            Catecismo.json = data;
        });

        // Trata parâmetros na URL
        const params = Utils.getUrlParams();
        if (params.pagina) {
            Utils.loadHtml(params.pagina + '.html', '#doccat', function() {
                switch (params.pagina) {
                    case 'catecismo':
                        Catecismo.montaPagina(params);
                        break;
                    case 'tribos':
                        // Nada
                        break;
                    default:
                        break;
                }
            });
        }
    }
    
    static refReplace(selector) {
        $('ref-biblia').each(function() {
            // TODO Fazer uma pesquisa no Google ou mandar pra algum site enquanto não tenho o texto.
            const replacement = this.innerHTML;
            $(this).replaceWith($('<span style="border: 1px dashed #00f !important; border-radius: 4px;">').append(replacement));
        });
    
        $('ref-cic').each(function() {
            let name = $(this).attr('name');
            name = name ? name : this.innerText;
            let replacement = $('<a onclick="javascript:Catecismo.referencia(\'' + name + '\');">').append(this.innerHTML);
            if (selector == '#grupo') { // Se o link vier da barra de grupo, colocar na estrutura do texto
                const grupo = Catecismo.cic2grupo(name);
                replacement = $('<a href="?pagina=catecismo&grupo=' + grupo + '&cic=' + name + '">').append(this.innerHTML);
            }
            $(this).replaceWith(replacement);
        });
    }
}

class Catecismo {
    static json = null;
    static #cic2grupo = null;
    static #cicEmOrdem = null;

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
            Utils.loadHtml('catecismo/' + params.grupo, '#grupo', function() {
                if (params.cic) {
                    $('#grupo a[href^="?pagina=catecismo"][href$="&cic=' + params.cic + '"]').parent().parent().addClass('selecionado');
                    Utils.loadHtml('catecismo/' + params.grupo + '/cic_' + params.cic + '.html', '#texto', function() {
                        const navegador = $('<div class="navegador">');
                        const anterior = Catecismo.cicAnterior(params.cic);
                        if (anterior != null) {
                            navegador.append($('<ref-cic name="' + anterior + '">&#129092;</ref-cic>'));
                        }
                        const posterior = Catecismo.cicPosterior(params.cic);
                        if (posterior != null) {
                            navegador.append($('<ref-cic name="' + posterior + '">&#129094;</ref-cic>'));
                        }
                        $('#texto').append(navegador);
                        DocCat.refReplace("#grupo");
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
                break;
        }
    }
}

$(document).ready(function () {
    DocCat.inicializa();
});
