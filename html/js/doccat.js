"use strict";

$(document).ready(function () {
    new Frontend();
});

class Utils {
    static downloadString(str, fileName) {
        const downloader = document.createElement('a');
        downloader.style.display = 'none';
        downloader.href = 'data:attachment/text,' + encodeURIComponent(str);
        downloader.target = '_blank';
        downloader.download = fileName;
        downloader.click();
    }

    static formatDateYYYYMMDDHHNNSS(date) {
        return new Date(date.getTime() - (date.getTimezoneOffset() * 60000)).toISOString().replace('T', '-').replaceAll(':', '-').split('.')[0];
    }
}

class Storage {
    static exportar() {
        const result = {};
        for (var key in localStorage){
            result[key] = localStorage[key];
        }
        Utils.downloadString(JSON.stringify(result), 'doccat.anotacoes.' + Utils.formatDateYYYYMMDDHHNNSS(new Date()) + '.json');
    }

    static importar() {
        $('#storageUpload').removeClass('d-none');
    }

    static importarOnChange(evt) {
        $('#storageUpload').addClass('d-none');
        $('#storageUploadSpinner').removeClass('d-none');
        const file = $('#storageUpload input')[0].files[0];
        const reader = new FileReader();
        let excluir = Object.keys(localStorage);
        reader.onload = function(event) {
            const result = JSON.parse(event.target.result);
            for (var key in result){
                if (key == 'length') {
                    continue;
                }
                console.log(result[key]);
                Storage.setItem(key, result[key]);
                const indexOf = excluir.indexOf(key);
                if (indexOf >= 0) {
                    excluir.splice(indexOf, 1);
                }
            }
            debugger;
            for (const key of excluir) {
                Storage.setItem(key, null);
            }
            $('#storageUploadSpinner').addClass('d-none');
            $('#storageUpload input').val(null);
            window.location.reload();
        }
        reader.readAsText(file);
    }

    static getItem(key) {
        try {
            return localStorage[key];
        } catch {
            return null;
        }
    }

    static setItem(key, val) {
        if (val) {
            localStorage[key] = val;
        } else {
            localStorage.removeItem(key);
        }
        Storage.updateMenu();
    }
    
    // @deprecated
    static updateMenu() {
        $($('#storageMenu a')[0]).text('Anotações (' + localStorage.length + ')');
    }
}
