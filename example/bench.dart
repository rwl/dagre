// This program tests the quality of the dagre odering algorithm.

//var path = require('path'),
//    fs = require('fs'),
//    dagre = require('../index'),
//    util = require('../lib/util'),
//    dot = require('graphlib-dot');

//var benchmarkFiles = process.argv.slice(2);
//if (benchmarkFiles.length == 0) {
//  process.stderr.write('Usage: ' + __filename + ' [DOT file]+\n');
//  process.exit(1);
//}

var IGNORE_PATTERN = "Input graph is not acyclic";

main() {
  var samples = [];
  var times = [];
  var skipped = 0;
  var ignored = 0;
  var failed = 0;

  //process.on('SIGINT', function() {
  //  console.log('\n\n!! Aborting...');
  //  process.exit(1);
  //});
  //process.on('exit', () { finish(); });

  // Start the loop
  handleNext();
}

handleNext() {
  var entry = benchmarkFiles.pop();
  if (entry == undefined) {
    return;
  }

  if (fs.statSync(entry).isDirectory()) {
    pushDirectory(entry);
  } else {
    processFile(entry);
  }
}

pushDirectory(dir) {
  fs.readdir(dir, (err, files) {
    if (err) throw err;
    files.forEach((file) {
      benchmarkFiles.push(path.resolve(dir, file));
    });
    handleNext();
  });
}

processFile(file) {
  process.stdout.write(leftPad(20, file) + ': ');
  fs.readFile(file, (err, data) {
    if (err) throw err;
    var f = data.toString('utf-8');
    try {
      var g = dot.parse(f);
      // Try a few restarts in the order phase
      //g.graph().orderRestarts = 1;
      var start = new Date().getTime();
      var g2 = dagre.layout().run(g);
      var end = new Date().getTime();
      var pre = g2.graph().orderInitCC;
      if (pre > 0) {
        var post = g2.graph().orderCC;
        var eff = (pre - post) / pre;
        console.log('SUCCESS  -' +
                    '  PRE: ' + leftPad(8, pre) +
                    '  POST: ' + leftPad(8, post) +
                    '  Efficiency: ' + leftPad(8, eff.toString().substring(0, 8)) +
                    '  Time: ' + leftPad(5, (end - start)) + 'ms');
        samples.push(eff);
        times.push(end - start);
      } else {
        console.log('SKIPPING - 0 CROSSINGS');
        ++skipped;
      }
    } catch (e) {
      if (e.toString().match(IGNORE_PATTERN)) {
        console.log('IGNORING - ' + e.toString().split('\n')[0]);
        ++ignored;
      } else {
        console.log('FAILED   - ' + e.toString().split('\n')[0]);
        ++failed;
      }
    }
    handleNext();
  });
}

finish() {
  console.log();
  console.log('Results');
  console.log('-------');
  console.log('# Graphs: ' + leftPad(8, samples.length + skipped + ignored + failed));
  console.log('Skipped : ' + leftPad(8, skipped));
  console.log('Ignored : ' + leftPad(8, ignored));
  console.log('Failed  : ' + leftPad(8, failed));
  console.log('Reduction efficiency (larger is better): ' + (util.sum(samples) / samples.length));
  console.log('Execution time: ' + util.sum(times) + 'ms (avg: ' + Math.round(util.sum(times) / times.length) + 'ms)');
}

leftPad(len, str) {
  var result = [];
  for (i = 0; i < len; ++i) {
    result.push(' ');
  }
  result.push(str);
  return result.join('').slice(-len);
}
