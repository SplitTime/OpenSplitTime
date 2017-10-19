module.exports = {
    /**
     * 
     * @param {*} obj 
     * @param {*} prop 
     * @param {*} value 
     */
    const(obj, prop, value) {
        Object.defineProperty(obj, prop, {
            value,
            writable: false,
            enumerable: false,
            configurable: false
        });
    },

    /**
     * 
     * @param {*} obj 
     * @param {*} prop 
     * @param {*} value 
     */
    hidden(obj, prop, value = undefined) {
        Object.defineProperty(obj, prop, {
            value,
            writable: true,
            enumerable: false,
            configurable: false
        });
    }
};