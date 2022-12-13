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

class Frontend {
    #backend;

    static loadCss(arquivo) {
        $(`<link href="css/${arquivo}" rel="stylesheet">`).appendTo("head");
    }

    // TODO Terminar
    static loadHtml(arquivo, selector, callback) {
        $(selector).empty();
        $(selector).append('<div class="spinner-border" role="status">');
        $(selector).load(arquivo, function(response, status, xhr) {
            switch (status) {
                case 'success':
        //             if (selector == '#referencia') {
        //                 $(selector).prepend($('<label class="form-label">').append('Referência'));
        //             }
    
                    // DocCat.refReplace(selector);
                    if (callback) {
                        callback();
                    }
                    break;
                    
        //         case 'error':
        //             // TODO Fazer um script PowerShell pra identificar o que deveria existir, para distinguiar o que ainda não foi feito do que realmente não existe (se xhr.status for 404)
        //             $(selector).empty();
        //             $(selector)
        //                 .append($('<div class="alert alert-danger">')
        //                     .append($('<b>')
        //                         .append(xhr.status)
        //                         .append(' ')
        //                         .append(xhr.statusText))
        //                     .append(response));
        //             break;
    
        //         default:
        //             throw 'Não sei tratar "' + status + '"'; // TODO Tratar "notmodified", "nocontent", "timeout", "abort", or "parsererror"
            }
        });
    }

    constructor() {
        this.createBackend();
        
        this.updateMenu();

        this.updatePage();
    }

    createBackend() {
        this.#backend = new Backend();
    }

    // Atualiza o menu com o número de anotações
    async updateMenu() {
        this.#backend.getItemCount().then((response) => {
            $($('#storageMenu a')[0]).text(`Anotações (${response})`);
        });
    }

    async updatePage() {
        let params = UrlUtils.getUrlParams();
        const pagina = params.pagina;
        if (pagina) {
            delete params.pagina
            switch (pagina) {
                case 'biblia':
                    new Biblia('#doccat', params);
                    break;
                default:
                    // TODO Colocar mensagem na tela
                    throw "Página desconhecida";
            }
        }
    }
}
