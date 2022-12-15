"use strict";

class Livro {
    #frontend;

    // static capitulo(capitulo) {
    //     const params = UrlUtils.getUrlParams();
    //     params.capitulo = capitulo;
    //     UrlUtils.gotoUrl(UrlUtils.getUrl(params));
    // }

    // static livro(sigla) {
    //     const params = UrlUtils.getUrlParams();
    //     params.livro = sigla;
    //     if (params.capitulo) {
    //         delete params.capitulo
    //     }
    //     UrlUtils.gotoUrl(UrlUtils.getUrl(params));
    // }

    constructor(frontend, selector, params) {
        this.#frontend = frontend;
        Frontend.loadCss('livro.css');
        if (params.nome) {
            Frontend.loadHtml(`livro/${params.nome}`, selector, this.#onLoadLivro.bind(this, params));
        } else {
            Frontend.loadHtml('livro', selector);
        }
    }

    #onLoadLivro(params) {
        if (params.estrutura) {
            this.#frontend.setupAnotacoes(`/livro/${params.nome}/${params.estrutura}`);
        }
    }
}
