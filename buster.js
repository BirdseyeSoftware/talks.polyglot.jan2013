var config = exports;

config['Browser Tests'] = {
    environment: 'browser',
    sources: ["build/bundle.js"],
    resources: [{
        path: "/",
        file: "slides.html"
    }],
    tests: ["test/*_test.js"]
};

config['Node Tests'] = {
    environment: 'node',
    sources: ["lib/*.js"],
    tests: ["test/*_test.js"]
};
