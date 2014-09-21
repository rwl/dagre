library dagre.util;

import 'dart:math' as Math;
import 'dart:collection' show SplayTreeMap;

import 'package:graphlib/graphlib.dart' show BaseGraph;

/**
 * Returns the smallest value in the array.
 */
min(Iterable values) {
  return values.reduce(Math.min);
}

/**
 * Returns the largest value in the array.
 */
max(Iterable values) {
  return values.reduce(Math.max);
}

/**
 * Returns `true` only if `f(x)` is `true` for all `x` in `xs`. Otherwise
 * returns `false`. This function will return immediately if it finds a
 * case where `f(x)` does not hold.
 */
all(List xs, f(x)) {
  for (var i = 0; i < xs.length; ++i) {
    if (!f(xs[i])) {
      return false;
    }
  }
  return true;
}

/**
 * Accumulates the sum of elements in the given array using the `+` operator.
 */
num sum(Iterable values) {
  if (values.length == 0) return 0;
  return values.reduce((acc, x) { return acc + x; });//, 0);
}

/*
 * Returns an array of all values in the given object.
 */
//values(obj) {
//  return Object.keys(obj).map((k) { return obj[k]; });
//}

shuffle(List array) {
  final r = new Math.Random();
  for (var i = array.length - 1; i > 0; --i) {
    int j = (r.nextDouble() * (i + 1)).floor();
    var aj = array[j];
    array[j] = array[i];
    array[i] = aj;
  }
}

//propertyAccessor(self, config, field, setHook) {
//  return (x) {
//    if (!arguments.length) return config[field];
//    config[field] = x;
//    if (setHook) setHook(x);
//    return self;
//  };
//}

/**
 * Given a layered, directed graph with `rank` and `order` node attributes,
 * this function returns an array of ordered ranks. Each rank contains an array
 * of the ids of the nodes in that rank in the order specified by the `order`
 * attribute.
 */
List<List> ordering(BaseGraph g) {
  final ordering = new SplayTreeMap<int, SplayTreeMap>();
  g.eachNode((u, Map value) {
    final r = value['rank'];
    if (r == null) return; // TODO: undefined ordering
    if (!ordering.containsKey(r)) {
      ordering[r] = new SplayTreeMap();
    }
    final rank = ordering[r];
    rank[value['order']] = u;
  });
  return ordering.values.map((SplayTreeMap m) => m.values.toList()).toList();
}

/*
 * A filter that can be used with `filterNodes` to get a graph that only
 * includes nodes that do not contain others nodes.
 */
filterNonSubgraphs(g) {
  return (u) {
    return g.children(u).length == 0;
  };
}

/*
 * Returns a new function that wraps `func` with a timer. The wrapper logs the
 * time it takes to execute the function.
 *
 * The timer will be enabled provided `log.level >= 1`.
 */
Object time(String name, Function func) {
  //return () {
    final start = new DateTime.now().millisecondsSinceEpoch;
    try {
      return func();//.apply(null, arguments);
    } finally {
      log(1, "$name time: ${new DateTime.now().millisecondsSinceEpoch - start}ms");
    }
  //};
}
bool time_enabled = false;

//exports.time = time;

/*
 * A global logger with the specification `log(level, message, ...)` that
 * will log a message to the console if `log.level >= level`.
 */
log(int level, String msg) {
  if (log_level >= level) {
    //console.log.apply(console, Array.prototype.slice.call(arguments, 1));
    print(msg);
  }
}
int log_level = 0;

//exports.log = log;


Set union(Iterable<Iterable> sets) {
  var s = new Set();
  for (var ss in sets) {
    s = s.union(ss.toSet());
  }
  return s;
}
