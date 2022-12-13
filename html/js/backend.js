"use strict";

class Backend {
    async getItemCount() {
        return localStorage.length;
    }
}
