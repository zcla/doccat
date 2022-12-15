"use strict";

class UrlUtils {
    static getUrl(paramArray) {
        let url = `${location.origin}${location.pathname}`;
        let separator = '?';
        for (const key of Object.keys(paramArray)) {
            const val = paramArray[key];
            url = `${url}${separator}${encodeURIComponent(key)}=${encodeURIComponent(val)}`
            separator = '&';
        }
        return url;
    }

    static getUrlParams() {
        const result = {};
        const paramArray = location.search.replace('?', '').split('&');
        for (const param of paramArray) {
            if (param) {
                let [key, value] = param.split('=');
                key = decodeURIComponent(key);
                value = decodeURIComponent(value);
                result[key] = decodeURIComponent(value);
            }
        }
        return result;
    }

    static gotoUrl(url) {
        window.location.href = url;
    }
}

class Anotacoes {
    #id;
    #backend;

    static setupGenericEvents() {
        // Negrito com click no botão
        $('#anotacoes_btn_negrito').click(function() {
            Anotacoes.toolbarNegrito();
        });
        // Itálico com click no botão
        $('#anotacoes_btn_italico').click(function() {
            Anotacoes.toolbarItalico();
        });
        $('#anotacoes textarea').keypress(function(e) {
            // Negrito com Ctrl+B
            if (e.ctrlKey && e.keyCode == 2) {
                Anotacoes.toolbarNegrito();
            }
            // Itálico com Ctrl+I
            if (e.ctrlKey && e.keyCode == 9) {
                Anotacoes.toolbarItalico();
            }
        });
    }

    static toolbarInsertPrefixoSufixo(prefixo, sufixo) {
        let start = $('#anotacoes textarea').prop('selectionStart');
        let end = $('#anotacoes textarea').prop('selectionEnd');
        let val = $('#anotacoes textarea').val();
        if ((val.substring(start - prefixo.length, start) == prefixo) && (val.substring(end, end + sufixo.length) == sufixo)) {
            // remover
            val = val.substr(0, start - prefixo.length) + val.substring(start, end) + val.substring(end + sufixo.length);
            start = start - prefixo.length;
            end = end - prefixo.length;
        } else {
            // adicionar
            val = val.substring(0, start) + prefixo + val.substring(start, end) + sufixo + val.substring(end);
            start = start + prefixo.length;
            end = end + prefixo.length;
        }
        $('#anotacoes textarea').val(val);
        $('#anotacoes textarea').prop('selectionStart', start);
        $('#anotacoes textarea').prop('selectionEnd', end);
        $('#anotacoes textarea').trigger('input');
        $('#anotacoes textarea').focus();
    }

    static toolbarNegrito() {
        Anotacoes.toolbarInsertPrefixoSufixo('**', '**');
    }

    static toolbarItalico() {
        Anotacoes.toolbarInsertPrefixoSufixo('*', '*');
    }

    constructor(id, backend) {
        this.#id = id;
        this.#backend = backend;
        Frontend.loadHtml('anotacoes.html', '#anotacoes_placeholder', this.#onLoadAnotacoes.bind(this));
    }

    #onLoadAnotacoes() {
        $('#anotacoes_id').empty();
        $('#anotacoes_id').append(this.#id);
        this.#backend.getItem(this.#id).then((response) => {
            $('#anotacoes textarea').val(response);
            this.#onInputAnotacoesTextarea(this.#id);
            this.updateContador();

            $('#anotacoes textarea').on('input', this.#onInputAnotacoesTextarea.bind(this));

            Anotacoes.setupGenericEvents();
        });
    }

    #onInputAnotacoesTextarea() {
        const val = $('#anotacoes textarea').val();
        this.#backend.setItem(this.#id, val);
        this.updateContador();
        this.updatePreview();
    }

    updateContador() {
        this.#backend.getItemCount().then((response) => {
            $($('#storageMenu a')[0]).text(`Anotações (${response})`);
        });
    }

    updatePreview() {
        const val = $('#anotacoes textarea').val();
        $('#anotacoes_preview').html(marked.parse(val));
        // TODO Referências
    }
}

class Frontend {
    #backend;

    static loadCss(arquivo) {
        $(`<link href="css/${arquivo}" rel="stylesheet">`).appendTo("head");
    }

    static loadHtml(arquivo, selector, callback) {
        $(selector).empty();
        $(selector).append('<div class="spinner-border" role="status">');
        $(selector).load(arquivo, function(response, status, xhr) {
            switch (status) {
                case 'success':
                    if (callback) {
                        callback();
                    }
                    break;
                    
                    case 'error':
                        $(selector).empty();
                        $(selector).append(`
                            <div class="alert alert-danger">
                                <b>${xhr.status} ${xhr.statusText}</b>
                                ${response}
                            </div>
                        `);
                        break;
    
                    default:
                        Frontend.adicionaMensagem('danger', 'Status desconhecido!', `${status}`);
            }
        });
    }

    static adicionaMensagem(tipo, titulo, mensagem) {
        $('#mensagens').append(`
            <div class="alert alert-${tipo}">
                <b>${titulo}</b>
                <p>${mensagem}</p>
            </div>
        `);
    }

    constructor() {
        this.createBackend();
        this.updatePage();
    }

    createBackend() {
        this.#backend = new Backend();
    }

    setupAnotacoes(id) {
        new Anotacoes(id, this.#backend);
    }

    updatePage() {
        let params = UrlUtils.getUrlParams();
        const pagina = params.pagina;
        if (pagina) {
            delete params.pagina
            switch (pagina) {
                case 'biblia':
                    new Biblia(this, '#doccat', params);
                    break;
                case 'livro':
                    new Livro(this, '#doccat', params);
                    break;
                default:
                    Frontend.adicionaMensagem('danger', 'Erro!', `Página desconhecida: <i>${pagina}</i>.`);
                    throw "Página desconhecida";
            }
        }
    }
}
