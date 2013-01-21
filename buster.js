var config = exports;

config['Browser Tests'] = {
    environment: 'browser',
    sources: ["build/bundle.js"],
    resources: [{
        path: "/",
        file: "build/slides.html"
    }],
    tests: ["test/browser_test.js"]
};

config['Node Tests'] = {
    environment: 'node',
    tests: ["test/node_test.js",
            "test/app.core.test.js"
           ]
};
