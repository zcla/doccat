"use strict";

function loadHtml(arquivo, selector, callback) {
    $(selector).empty();
    $(selector).append('<div class="spinner-border" role="status">');
    $(selector).load(arquivo, function(response, status, xhr) {
        switch (status) {
            case 'success':
                refReplace(selector);
                if (callback) {
                    callback();
                }
                break;
                
            case 'error':
                $(selector).empty();
                $(selector)
                    .append($('<div class="alert alert-danger">')
                        .append(response)
                        .append('<hr>')
                        .append(xhr.status)
                        .append(' ')
                        .append(xhr.statusText));
                break;

            default: // TODO Tratar "notmodified", "nocontent", "timeout", "abort", or "parsererror"
                console.log('Não sei tratar "' + status + '"');
                break;
        }
    });
}

function getUrlParams() {
    const paramArray = location.search.replace('?', '').split('&');
    const result = {};
    for (const param of paramArray) {
        const [key, value] = param.split('=');
        result[key] = value;
    }
    return result;
}

function refReplace(selector) {
    $('ref-biblia').each(function() {
        const replacement = this.innerHTML;
        $(this).replaceWith(replacement);
    });

    $('ref-cic').each(function() {
        let name = $(this).attr('name');
        name = name ? name : this.innerText;
        let replacement = $('<a onclick="javascript:Catecismo.referencia(\'' + name + '\');">').append(this.innerHTML); // TODO Trocar por href: buscar o que já tem e acrescentar "referencia"
        if (selector == '#grupo') { // Se o link vier da barra de grupo, colocar na estrutura do texto
            const params = getUrlParams();
            replacement = $('<a href="?pagina=' + params.pagina + '&grupo=' + params.grupo + '&cic=' + name + '">').append(this.innerHTML);
        }
        $(this).replaceWith(replacement);
    });
}

$(document).ready(function () {
    // Trata parâmetros na URL
    const params = getUrlParams();
    if (params.pagina) {
        loadHtml(params.pagina + '.html', '#doccat', function() {
            switch (params.pagina) {
                case 'catecismo':
                    Catecismo.montaPagina(params)
                    break;
                case 'tribos':
                    // Nada
                    break;
                default:
                    break;
            }
        });
    }
});

class Catecismo {
    static montaPagina(params) {
        if (params.grupo) {
            $('#mestre a[href="?pagina=catecismo&grupo=' + params.grupo + '"]').parent().parent().addClass('selecionado');
            loadHtml('catecismo/grupo/' + params.grupo + '.html', '#grupo', function() {
                if (params.cic) {
                    $('#grupo a[href^="?pagina=catecismo"][href$="&cic=' + params.cic + '"]').parent().parent().addClass('selecionado');
                    loadHtml('catecismo/cic_' + params.cic + '.html', '#texto');
                    // TODO "Navegadores". Ordem: prologo -> 1-184 -> credo -> 185...
                }
            });
        }
    }

    // Mostra o texto como referência
    static referencia(referencia) {
        loadHtml('catecismo/cic_' + referencia + '.html', '#referencia');
    }
}
