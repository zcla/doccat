"use strict";

class Catecismo {
    #frontend;
    #selector;
    #params;
    
    static #catecismo;
    static #cic2grupo = null;
    static #cicEmOrdem = null;

    static cic2grupo(cic) {
        if (!this.#cic2grupo) {
            this.#cic2grupo = {};
            for (const grupo of this.#catecismo) {
                for (const cic of grupo.cic) {
                    this.#cic2grupo[cic] = grupo.grupo;
                }
            }
        }
        return this.#cic2grupo[cic];
    }

    static cicPosicao(cic) {
        if (!this.#cicEmOrdem) {
            this.#cicEmOrdem = [];
            for (const grupo of this.#catecismo) {
                for (const cic of grupo.cic) {
                    this.#cicEmOrdem.push(cic);
                }
            }
        }
        return this.#cicEmOrdem.indexOf(cic);
    }

    static cicAnterior(cic) {
        const pos = this.cicPosicao(cic);
        if (pos > 0) {
            return this.#cicEmOrdem[pos - 1];
        }
        return null;
    }

    static cicPosterior(cic) {
        const pos = this.cicPosicao(cic);
        if (pos < this.#cicEmOrdem.length) {
            return this.#cicEmOrdem[pos + 1];
        }
        return null;
    }

    static replaceReferences() {
        $('ref-cic').each(function() {
            let numero = $(this).attr('numero');
            numero = numero ? numero : this.innerText;
            let replacement = $(this);
            let hrefReplacement = `?pagina=catecismo`;
            let grupo = $(this).attr('grupo');
            if (!grupo) {
                grupo = Catecismo.cic2grupo(numero);
                hrefReplacement += `&grupo=${grupo}`;
            }
            hrefReplacement += `&cic=${numero}`;
            replacement = $(`<a href="${hrefReplacement}">`).append(this.innerHTML);
            $(this).replaceWith(replacement);
        });
    }

    constructor(frontend, selector, params) {
        this.#frontend = frontend;
        this.#selector = selector;
        this.#params = params;
        Frontend.loadCss('catecismo.css');
        Frontend.loadJson(`json/catecismo.json`, this.#onLoadCatecismoJson.bind(this));
    }

    #onLoadCatecismoJson(data) {
        Catecismo.#catecismo = data;
        Frontend.loadHtml('catecismo/index.html', this.#selector, this.#onLoadCatecismoLista.bind(this));
    }

    #onLoadCatecismoLista() {
        let estruturaClasses = [ 'col-12' ];
        let grupoTextoReferenciaClasses = [ 'd-none' ];
        let anotacoesPreviewClasses = [ 'd-none' ];
        if (this.#params.grupo) {
            estruturaClasses = [ 'col-6' ];
            grupoTextoReferenciaClasses = [ 'col-6' ];
            $('#estrutura a[href="?pagina=catecismo&grupo=' + this.#params.grupo + '"]').parent().parent().addClass('selecionado');
            if (this.#params.cic) {
                estruturaClasses = [ 'col-2', 'tresColunas' ];
                grupoTextoReferenciaClasses = [ 'col-6' ];
                anotacoesPreviewClasses = [ 'col-4' ];
            }
            Frontend.loadHtml('catecismo/' + this.#params.grupo, '#grupo', this.#onLoadCatecismoGrupo.bind(this));
        }
        $('#estrutura').removeClass();
        estruturaClasses.forEach(function(className) { $('#estrutura').addClass(className) });
        $('#grupoTextoReferencia').removeClass();
        grupoTextoReferenciaClasses.forEach(function(className) { $('#grupoTextoReferencia').addClass(className) });
        $('#anotacoesPreview').removeClass();
        anotacoesPreviewClasses.forEach(function(className) { $('#anotacoesPreview').addClass(className) });
    }

    #onLoadCatecismoGrupo() { // TODO Está carregando duas vezes o grupo, sei lá por quê.
        if (this.#params.cic) {
            $('#grupo a[href^="?pagina=catecismo"][href$="&cic=' + this.#params.cic + '"]').parent().parent().addClass('selecionado');
            Frontend.loadHtml('catecismo/' + this.#params.grupo + '/cic_' + this.#params.cic + '.html', '#texto', this.#onLoadCatecismoNumero.bind(this));
        }
    }

    #onLoadCatecismoNumero() {
        class Numero {
            #catecismo;
            #params;

            constructor(catecismo, params) {
                this.#catecismo = catecismo;
                this.#params = params;
            }

            #grupo() {
                return this.#catecismo.find((catecismo) => catecismo.grupo == this.#params.grupo);
            }

            anterior() {
                const grupo = this.#grupo();
                const pos = grupo.cic.indexOf(this.#params.cic);
                if (pos > 0) {
                    return grupo.cic[pos - 1];
                }
                const posGrupo = this.#catecismo.indexOf(grupo);
                if (posGrupo > 0) {
                    return this.#catecismo[posGrupo - 1].cic[this.#catecismo[posGrupo - 1].cic.length - 1];
                }
                return null;
            }

            posterior() {
                const grupo = this.#grupo();
                const pos = grupo.cic.indexOf(this.#params.cic);
                if (pos < grupo.cic.length - 1) {
                    return grupo.cic[pos + 1];
                }
                const posGrupo = this.#catecismo.indexOf(grupo);
                if (pos < this.#catecismo.length - 1) {
                    return this.#catecismo[posGrupo + 1].cic[0];
                }
                return null;
            }
        }

        // TODO this.#trataLinks_abrirEmNovaAba('texto');
        this.#trataLinks_mostrarNaAreaDeReferencia('texto');
        this.#frontend.setupAnotacoes(`/catecismo/${this.#params.cic}`, this.#setupAnotacoesCallback.bind(this));
        $('#anotacoes_placeholder').addClass('col-4');
        $('#anotacoes_placeholder').removeClass('d-none');

        // Adiciona os navegadores
        const navegador = $('<div id="textoNavegador" class="navegador">');
        const num = new Numero(Catecismo.#catecismo, this.#params);
        const anterior = num.anterior();
        if (anterior) {
            navegador.append($(`<ref-cic numero="${anterior}">&#129092;</ref-cic>`));
        }
        const posterior = num.posterior();
        if (posterior) {
            navegador.append($(`<ref-cic numero="${posterior}">&#129094;</ref-cic>`));
        }
        $('#texto').append(navegador);
    }

    #setupAnotacoesCallback() {
        // TODO this.#trataLinks_abrirEmNovaAba('anotacoes_preview');
        this.#trataLinks_mostrarNaAreaDeReferencia('anotacoes_preview');
    }

    #trataLinks_mostrarNaAreaDeReferencia(elementId) {
        const catecismo = this;
        // Links para os parágrafos; não para a "raiz" de documentos
        $(`#${elementId} a[href^="?pagina=catecismo&"][href*="&cic="]`).each(function(index, element) {
            const href = $(element).attr('href');
            const params = UrlUtils.getUrlParams(href);
            $(element).click(function() {
                catecismo.mostraReferencia(params);
            });
            $(element).removeAttr('href');
        });
    }

    mostraReferencia(params) {
        Frontend.loadHtml('catecismo/' + params.grupo + '/cic_' + params.cic + '.html', '#referencia');
    }
}
