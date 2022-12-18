"use strict";

class Biblia {
    #frontend;
    #params;
    #versao = 'combo';

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
        this.#params = params;
        Frontend.loadCss('biblia.css');
        Frontend.loadHtml('biblia', selector, this.#onLoadBiblia.bind(this));
    }

    #onLoadBiblia() {
        $('#versao').change(function(eventObject) {
            const params = UrlUtils.getUrlParams();
            params.versao = $('#versao').val();
            UrlUtils.gotoUrl(UrlUtils.getUrl(params));
        });
        if (this.#params.versao) {
            this.#versao = this.#params.versao
            $('#versao').val(this.#versao);
            const versao = this.#versao;
            $('#estrutura a[href^="?pagina=biblia&livro="]').each(function(index, element) {
                $(element).attr('href', $(element).attr('href') + `&versao=${versao}`);
            })
        }
        if (this.#params.livro) {
            $(`#estrutura a[href^="?pagina=biblia&livro=${this.#params.livro}"]`).parent().addClass('selecionado');
            Frontend.loadHtml(`biblia/${this.#versao}/${this.#params.livro}`, '#livro', this.#onLoadLivro.bind(this));
        }
    }

    #onLoadLivro() {
        if (this.#params.capitulo) {
            Frontend.loadHtml(`biblia/${this.#versao}/${this.#params.livro}/${this.#params.capitulo}`, '#capitulo');
            this.#frontend.setupAnotacoes(`/biblia/${this.#versao}/${this.#params.livro}/${this.#params.capitulo}`);
        }
    }
}
