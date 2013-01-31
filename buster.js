var config = exports;

config['Browser Tests'] = {
    environment: 'browser',
    sources: ["build/bundle.js"],
    resources: [{
        path: "/",
        file: "build/slides.html"
    }],
    tests: []
};

config['Node Tests'] = {
    environment: 'node',
    tests: ["test/app.core.test.js"]
};
