"use strict";

class Documento {
    #frontend;
    #selector;
    #params;
    #documentos;

    static replaceReferences() {
        $('ref-doc').each(function() {
            const doc = $(this).attr('id');
            const paragrafo = $(this).attr('paragrafo');
            let replacement = $(this);
            let hrefReplacement = `?pagina=documento&id=${doc}`;
            if (paragrafo) {
                hrefReplacement += `&paragrafo=${paragrafo}`;
            }
            replacement = $(`<a href="${hrefReplacement}">`).append(this.innerHTML);
            $(this).replaceWith(replacement);
        });
    }

    constructor(frontend, selector, params) {
        this.#frontend = frontend;
        this.#selector = selector;
        this.#params = params;
        Frontend.loadCss('documento.css');
        Frontend.loadJson(`json/documento.json`, this.#onLoadDocumentoJson.bind(this));
    }

    #onLoadDocumentoJson(data) {
        this.#documentos = data;
        Frontend.loadHtml('documento/index.html', this.#selector, this.#onLoadDocumentoLista.bind(this));
    }
    
    #onLoadDocumentoLista() {
        let estruturaClasses = [ 'col-12' ];
        let textoReferenciaClasses = [ 'd-none' ];
        let anotacoesPreviewClasses = [ 'd-none' ];
        if (this.#params.id) {
            const a = $(`#documentoLista a[href*="?pagina=documento&id=${this.#params.id}"]`);
            if (a.length) {
                const tr = a.parent().parent()[0];
                const nome = $(tr).find('.nome')[0].innerText;
                const tipo = $(tr).find('.tipo')[0].innerText;
                const autor = $(tr).find('.autor')[0].innerText;
                const data = $(tr).find('.data')[0].innerText;

                $('#documentoNome').append(nome);
                if (tipo) {
                    $('#documentoTipo').append(tipo);
                }
                if (autor != '-') {
                    $('#documentoAutor').append(autor);
                }
                if (data != '-') {
                    $('#documentoData').append(data);
                }
                Frontend.loadHtml(`documento/${this.#params.id}`, '#estrutura', this.#onLoadDocumentoEstrutura.bind(this));
                if (this.#params.paragrafo) {
                    estruturaClasses = [ 'col-3', 'tresColunas' ];
                    textoReferenciaClasses = [ 'col-5' ];
                    anotacoesPreviewClasses = [ 'col-4' ];
                    $('#estrutura a[href="?pagina=documento&id=' + this.#params.id + '"]').parent().parent().addClass('selecionado');
                }
            } else {
                if (this.#documentos[this.#params.id]) {
                    throw "Código antigo. O documento não está no html mas está no json. Documento novo? Não seria melhor mostrar um alerta?";
                    Frontend.loadHtml(`documento/${this.#params.id}`, '#estrutura');
                } else {
                    Frontend.adicionaMensagem('danger', 'Erro', `Documento "${this.#params.id}" não encontrado.`);
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
    }

    #onLoadDocumentoEstrutura() {
        if (this.#params.paragrafo) {
            $(`#estrutura a[href^="?pagina=documento&id=${this.#params.id}"][href$="&paragrafo=${this.#params.paragrafo}"]`).parent().parent().addClass('selecionado');
            Frontend.loadHtml(`documento/${this.#params.id}/${this.#params.paragrafo}.html`, '#texto', this.#onLoadDocumentoParagrafo.bind(this));
        }
    }

    #onLoadDocumentoParagrafo() {
        class Paragrafo {
            #documento;

            constructor(documento) {
                this.#documento = documento;
            }

            #documentosParagrafo(documento) {
                return this.#documento.#documentos[this.#documento.#params.id].paragrafo;
            }

            #paragrafoIndexOf() {
                return this.#documentosParagrafo().indexOf(this.#documento.#params.paragrafo);
            }

            anterior() {
                const pos = this.#paragrafoIndexOf();
                if (pos > 0) {
                    return this.#documentosParagrafo()[pos - 1];
                }
                return null;
            }

            posterior() {
                const pos = this.#paragrafoIndexOf();
                if (pos < this.#documentosParagrafo().length) {
                    return this.#documentosParagrafo()[pos + 1];
                }
                return null;
            }
        }

        Frontend.makeLinksOpenOnAnotherTab('#texto a[href*="?pagina=documento&id=');
        this.#frontend.setupAnotacoes(`/documento/${this.#params.id}/${this.#params.paragrafo}`, this.#setupAnotacoesCallback.bind(this));
        $('#anotacoes_placeholder').addClass('col-4');
        $('#anotacoes_placeholder').removeClass('d-none');

        // Adiciona os navegadores
        const navegador = $('<div id="textoNavegador" class="navegador">');
        const par = new Paragrafo(this);
        const anterior = par.anterior();
        if (anterior) {
            navegador.append($('<ref-doc id="' + this.#params.id + '" paragrafo="' + anterior + '">&#129092;</ref-paragrafo>'));
        }
        const posterior = par.posterior();
        if (posterior) {
            navegador.append($('<ref-doc id="' + this.#params.id + '" paragrafo="' + posterior + '">&#129094;</ref-paragrafo>'));
        }
        $('#texto').append(navegador);
    }

    #setupAnotacoesCallback() {
        const documento = this;
        $('#anotacoes_preview a[href^="?pagina=documento&"]').each(function(index, element) {
            const href = $(element).attr('href');
            const params = UrlUtils.getUrlParams(href);
            $(element).click(function() {
                documento.mostraReferencia(params.id, params.paragrafo);
            });
            $(element).removeAttr('href');
        });
    }

    mostraReferencia(documento, numero) {
        if (this.#documentos[documento]) {
            const spl = numero.split('-');
            switch (spl.length) {
                case 1:
                    Utils.loadHtml('documento/' + documento + '/' + numero + '.html', '#referencia');
                    break;
                case 2:
                    throw "Tratar referência de múltiplos números"// TODO
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
