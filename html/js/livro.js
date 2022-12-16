"use strict";

class Livro {
    #frontend;
    #selector;
    #params;

    constructor(frontend, selector, params) {
        this.#frontend = frontend;
        this.#selector = selector;
        this.#params = params;
        Frontend.loadCss('livro.css');
        if (params.id) {
            Frontend.loadJson(`livro/${params.id}.json`, this.#onLoadLivro.bind(this));
        } else {
            Frontend.loadHtml('livro', selector);
        }
    }

    #onLoadLivro(data) {
        let html = `
<span id="livroTitulo">${data.titulo}</span>
<span id="livroAutor">${data.autor}</span>
<span id="livroEditora">${data.editora}</span>
<span id="livroAno">${data.ano}</span>
<div class="row">
	<div id="estrutura" class="col-6">
		<table class="table table-sm table-bordered table-hover">
			<thead>
				<tr>
					<th>Título</th>
					<th>Página</th>
				</tr>
			</thead>
			<tbody>
`
            for (const item of data.estrutura) {
                html += `
                <tr id="livro_${this.#params.id}_${item.id}">
                    <td class="indent${item.indent}"><a href="?pagina=livro&id=${this.#params.id}&estrutura=${item.id}">${item.texto}</a></td>
                    <td class="pagina">${item.pagina}</td>
                </tr>
    `
            }
            html += `
			</tbody>
		</table>
	</div>
	<div class="col-6" id="anotacoes_placeholder">
	</div>
</div>
`
        $(this.#selector).append(html);
        if (this.#params.estrutura) {
            $(`#livro_${this.#params.id}_${this.#params.estrutura}`).addClass('selecionado');
            this.#frontend.setupAnotacoes(`/livro/${this.#params.id}/${this.#params.estrutura}`);
        } else {
            this.#frontend.setupAnotacoes(`/livro/${this.#params.id}`);
        }
    }
}
