var pk = function () {
    var route = [];
    var handler = {
        get: function (_, name) {
            if (methods.includes(name)) {
                return function (_a) {
                    var _b = _a === void 0 ? {} : _a, _c = _b.data, data = _c === void 0 ? undefined : _c, _d = _b.query, query = _d === void 0 ? null : _d;
                    return new Promise(function (res, rej) { return scheduled.push({ res: res, rej: rej, axiosData: {
                            url: baseURL + "/" + route.join("/") + (query ? "?" + Object.keys(query).map(function (x) { return (x + "=" + query[x]); }).join("&") : ""),
                            method: name,
                            headers: {
                                authorization: PK_TOKEN,
                                "content-type": name == "get" ? undefined : "application/json"
                            },
                            data: !!data ? JSON.stringify(data) : undefined,
                            validateStatus: function () { return true; }
                        } }); });
                };
            }
            route.push(name);
            return new Proxy(noop, handler);
        },
        apply: function (target, _, args) {
            route.push.apply(route, args.filter(function (x) { return x != null; }));
            return new Proxy(noop, handler);
        }
    };
    return new Proxy(noop, handler);
};

