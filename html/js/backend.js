"use strict";

class Backend {
    async getItem(key) {
        return localStorage[key];
    }

    async getItemCount() {
        return localStorage.length;
    }

    async setItem(key, val) {
        if (val) {
            localStorage[key] = val;
        } else {
            localStorage.removeItem(key);
        }
    }
}
