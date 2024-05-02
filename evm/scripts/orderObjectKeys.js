const orderObjectKeys = function (obj) {
    if (typeof obj !== 'object' || obj === null) return obj;
    if (Array.isArray(obj)) return obj.map(orderObjectKeys);
    return Object.keys(obj)
        .sort()
        .reduce((acc, key) => {
            acc[key] = orderObjectKeys(obj[key]);
            return acc;
        }, {});
};

exports.orderObjectKeys = orderObjectKeys;
