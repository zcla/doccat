"use strict";

class Estudo {
    constructor(selector, params) {
        Frontend.loadHtml(`estudo/${params.id}.html`, selector);
        Frontend.loadCss(`estudo/${params.id}.css`);
    }
}
