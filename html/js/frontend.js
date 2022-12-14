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
                        $('#mensagens').append(`
                            <div class="alert alert-danger">
                                <b>Status desconhecido!</b>
                                <pre>${status}</pre>
                            </div>
                        `);
                        throw `Não sei tratar "${status}"`;
            }
        });
    }

    constructor() {
        this.createBackend();
        
        this.updateMenuAnotacoes();

        this.updatePage();
    }

    createBackend() {
        this.#backend = new Backend();
    }

    loadAnotacoes(idAnotacao) {
        Frontend.loadHtml('anotacoes.html', '#anotacoes_placeholder', this.#onLoadAnotacoes.bind(this, idAnotacao));
    }

    #onLoadAnotacoes(idAnotacao) {
        // Carrega a anotação
        this.#backend.getItem(idAnotacao).then((response) => {
            $('#anotacoes textarea').val(response);
            this.#onInputAnotacoesTextarea(idAnotacao);
            this.updateMenuAnotacoes();

            $('#anotacoes textarea').on('input', this.#onInputAnotacoesTextarea.bind(this, idAnotacao));

            $('#anotacoes_btn_negrito').click(function() {
                Anotacoes.toolbarNegrito();
            });
            $('#anotacoes_btn_italico').click(function() {
                Anotacoes.toolbarItalico();
            });
            $('#anotacoes textarea').keypress(function(e) {
                if (e.ctrlKey && e.keyCode == 2) { // Ctrl+B
                    Anotacoes.toolbarNegrito();
                }
                if (e.ctrlKey && e.keyCode == 9) { // Ctrl+I
                    Anotacoes.toolbarItalico();
                }
            });
        });
    }

    #onInputAnotacoesTextarea(idAnotacao) {
        const val = $('#anotacoes textarea').val();
        this.#backend.setItem(idAnotacao, val);
        this.updateMenuAnotacoes();
        this.updatePreviewAnotacoes();
    }

    // Atualiza o menu com o número de anotações
    updateMenuAnotacoes() {
        this.#backend.getItemCount().then((response) => {
            $($('#storageMenu a')[0]).text(`Anotações (${response})`);
        });
    }

    updatePreviewAnotacoes() {
        const val = $('#anotacoes textarea').val();
        $('#anotacoes_preview').html(marked.parse(val));
        // TODO Referências
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
                default:
                    // TODO Colocar mensagem na tela
                    // throw "Página desconhecida";
            }
        }
    }
}
