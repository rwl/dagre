library dagre.util;
//"use strict";

/*
 * Returns the smallest value in the array.
 */
min(values) {
  return Math.min.apply(Math, values);
}

/*
 * Returns the largest value in the array.
 */
max(values) {
  return Math.max.apply(Math, values);
}

/*
 * Returns `true` only if `f(x)` is `true` for all `x` in `xs`. Otherwise
 * returns `false`. This function will return immediately if it finds a
 * case where `f(x)` does not hold.
 */
all(xs, f) {
  for (var i = 0; i < xs.length; ++i) {
    if (!f(xs[i])) {
      return false;
    }
  }
  return true;
}

/*
 * Accumulates the sum of elements in the given array using the `+` operator.
 */
sum(values) {
  return values.reduce((acc, x) { return acc + x; }, 0);
}

/*
 * Returns an array of all values in the given object.
 */
values(obj) {
  return Object.keys(obj).map((k) { return obj[k]; });
}

shuffle(array) {
  for (var i = array.length - 1; i > 0; --i) {
    var j = Math.floor(Math.random() * (i + 1));
    var aj = array[j];
    array[j] = array[i];
    array[i] = aj;
  }
}

propertyAccessor(self, config, field, setHook) {
  return (x) {
    if (!arguments.length) return config[field];
    config[field] = x;
    if (setHook) setHook(x);
    return self;
  };
}

/*
 * Given a layered, directed graph with `rank` and `order` node attributes,
 * this function returns an array of ordered ranks. Each rank contains an array
 * of the ids of the nodes in that rank in the order specified by the `order`
 * attribute.
 */
ordering(g) {
  var ordering = [];
  g.eachNode((u, value) {
    var rank = ordering[value.rank] || (ordering[value.rank] = []);
    rank[value.order] = u;
  });
  return ordering;
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
time(name, func) {
  return () {
    var start = new Date().getTime();
    try {
      return func.apply(null, arguments);
    } finally {
      log(1, name + " time: " + (new Date().getTime() - start) + "ms");
    }
  };
}
//time.enabled = false;

//exports.time = time;

/*
 * A global logger with the specification `log(level, message, ...)` that
 * will log a message to the console if `log.level >= level`.
 */
log(level) {
  if (log_level >= level) {
    console.log.apply(console, Array.prototype.slice.call(arguments, 1));
  }
}
var log_level = 0;

//exports.log = log;
