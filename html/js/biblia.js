"use strict";

class Biblia {
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

    constructor(selector, params) {
        Frontend.loadCss('biblia.css');
        Frontend.loadHtml('biblia.html', selector, function() {
            $('#versao').change(function(eventObject) {
                const params = UrlUtils.getUrlParams();
                params.versao = $('#versao').val();
                UrlUtils.gotoUrl(UrlUtils.getUrl(params));
            });
            if (params.versao) {
                console.log("!");
                $('#versao').val(params.versao);
            }
            if (params.livro) {
                let versao = 'combo';
                if (params.versao) {
                    versao = params.versao;
                }
                Frontend.loadHtml('biblia/' + versao + '/' + params.livro, '#livro', function() {
                    if (params.capitulo) {
                        Frontend.loadHtml('biblia/' + versao + '/' + params.livro + '/' + params.capitulo, '#capitulo');
                    }
                });
            }
        });
    }
}
