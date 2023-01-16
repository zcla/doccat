"use strict";

class Estudo {
    constructor(selector, params) {
        if (params.livro) {
            Frontend.loadHtml(`estudo/${params.id}/${params.livro}.html`, selector);
        } else {
            Frontend.loadHtml(`estudo/${params.id}.html`, selector);
        }
        Frontend.loadCss(`estudo/${params.id}.css`);
    }
}
