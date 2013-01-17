var system = require('system'),
    captureUrl = 'http://localhost:1111/capture';
if (system.args.length==2) {
    captureUrl = system.args[1];
}
var captured = false;
var locked = false;
var captureAttempts = 0;
var page = new WebPage();

page.onConsoleMessage = function (msg, line, id) {
  var fileName = id.split('/');
  // format the output message with filename, line number and message
  // weird gotcha: phantom only uses the first console.log argument it gets :(
  console.log(fileName[fileName.length-1]+', '+ line +': '+ msg);
};

page.onAlert = function(msg) {
  console.log(msg);
};

var pageLoaded = function(status) {
    // console.log('Finished loading  with status: ' + status);
    var runnerFrame = page.evaluate(function() {
        return document.getElementById('session_frame');
    });

    if (!runnerFrame) {
        locked = false;
        setTimeout(capture, 1000);
    } else {
        captured = true;
    }
};

phantom.silent = false;
var capture = function() {
    if (captureAttempts === 5) {
        console.log('Failed to capture after ' + captureAttempts + ' attempts.');
        phantom.exit();
    }

    if (captured || locked) {
        return;
    }

    captureAttempts += 1;
    locked = true;

    page.open(captureUrl, function(status) {
        pageLoaded(status);
    });
};

capture();
