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
                        .append($('<b>')
                            .append(xhr.status)
                            .append(' ')
                            .append(xhr.statusText))
                        .append(response));
                break;

            default:
                throw 'Não sei tratar "' + status + '"'; // TODO Tratar "notmodified", "nocontent", "timeout", "abort", or "parsererror"
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
        // TODO Fazer uma pesquisa no Google ou mandar pra algum site enquanto não tenho o texto.
        const replacement = this.innerHTML;
        $(this).replaceWith(replacement);
    });

    $('ref-cic').each(function() {
        let name = $(this).attr('name');
        name = name ? name : this.innerText;
        let replacement = $('<a onclick="javascript:Catecismo.referencia(\'' + name + '\');">').append(this.innerHTML);
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
            loadHtml('catecismo/' + params.grupo, '#grupo', function() {
                if (params.cic) {
                    $('#grupo a[href^="?pagina=catecismo"][href$="&cic=' + params.cic + '"]').parent().parent().addClass('selecionado');
                    loadHtml('catecismo/' + params.grupo + '/cic_' + params.cic + '.html', '#texto');
                    // TODO "Navegadores". Ordem: prologo -> 1-184 -> credo -> 185...
                }
            });
        }
    }

    // Mostra o texto como referência
    static referencia(referencia) {
        // TODO Está qubrado; falta o grupo: http://127.0.0.1:5501/html/?pagina=catecismo&grupo=p1s1c1&cic=35
        // TODO Tratar referências múltiplas: http://127.0.0.1:5501/html/?pagina=catecismo&grupo=p1s1c2a2&cic=85
        loadHtml('catecismo/cic_' + referencia + '.html', '#referencia');
    }
}
