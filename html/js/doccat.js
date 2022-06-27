"use strict";

function loadHtml(arquivo, selector) {
    $(selector).empty();
    $(selector).load(arquivo, function() {
        refReplace();
    });
}

function refReplace() {
    $('ref-biblia').each(function() {
        const replacement = this.innerHTML;
        $(this).replaceWith(replacement);
    });

    $('ref-catecismodetalhe').each(function() {
        let name = $(this).attr('name');
        name = name ? name : this.innerText;
        const replacement = $('<a onclick="javascript:Catecismo.detalhe(\'' + name + '\');">').append(this.innerHTML);
        $(this).replaceWith(replacement);
    });

    $('ref-cec').each(function() {
        // TODO Se o elemento já estiver no texto, jogar em outro lugar e formatar como no documento, em itálico.
        let name = $(this).attr('name');
        name = name ? name : this.innerText;
        const replacement = $('<a onclick="javascript:Catecismo.texto(\'' + name + '\');">').append(this.innerHTML);
        $(this).replaceWith(replacement);
    });
}

$(document).ready(function () {
    // Trata parâmetros na URL
    const params = location.search.replace('?', '').split('&');
    for (const param of params) {
        const [key, value] = param.split('=')
        switch (key) {
            case "pagina":
                loadHtml(value + '.html', '#doccat');
                break;
            case "detalhe":
                // TODO Fazer só quando "pagina=catecismo"
                setTimeout(function() {
                    Catecismo.detalhe(value);
                }, 100); // TODO deixar mais "profissional" (carregar depois de loadHtml() terminar)
                break;
            default:
                throw "Parâmetro desconhecido";
        }
    }
});

class Catecismo {
    static detalhe(nome) {
        loadHtml('catecismo/' + nome + '.html', '#detalhe');
    }

    static texto(nome) {
        loadHtml('catecismo/cic_' + nome + '.html', '#texto');
        // TODO "Navegadores". Ordem: prologo -> 1-184 -> credo -> 185...
    }
}
