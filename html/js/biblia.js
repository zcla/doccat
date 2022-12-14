"use strict";

class Biblia {
    #frontend;

    static capitulo(capitulo) {
        const params = UrlUtils.getUrlParams();
        params.capitulo = capitulo;
        UrlUtils.gotoUrl(UrlUtils.getUrl(params));
    }

    static livro(sigla) {
        const params = UrlUtils.getUrlParams();
        params.livro = sigla;
        if (params.capitulo) {
            delete params.capitulo
        }
        UrlUtils.gotoUrl(UrlUtils.getUrl(params));
    }

    constructor(frontend, selector, params) {
        this.#frontend = frontend;
        Frontend.loadCss('biblia.css');
        Frontend.loadHtml('biblia.html', selector, this.#onLoadBiblia.bind(this, params));
    }

    #onLoadBiblia(params) {
        $('#versao').change(function(eventObject) {
            const params = UrlUtils.getUrlParams();
            params.versao = $('#versao').val();
            UrlUtils.gotoUrl(UrlUtils.getUrl(params));
        });
        if (params.versao) {
            console.log("!");
            $('#versao').val(params.versao);
        } else {
            params.versao = 'combo';
        }
        if (params.livro) {
            Frontend.loadHtml(`biblia/${params.versao}/${params.livro}`, '#livro', this.#onLoadLivro.bind(this, params));
        }
    }

    #onLoadLivro(params) {
        if (params.capitulo) {
            Frontend.loadHtml(`biblia/${params.versao}/${params.livro}/${params.capitulo}`, '#capitulo');
            this.#frontend.loadAnotacoes(`/biblia/${params.versao}/${params.livro}/${params.capitulo}`);
        }
    }
}
