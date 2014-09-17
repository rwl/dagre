library dagre.rank.util;

import 'package:graphlib/graphlib.dart';

/**
 * A helper to calculate the slack between two nodes ([u] and [v]) given a
 * [minLen] constraint. The slack represents how much the distance between [u]
 * and [v] could shrink while maintaining the [minLen] constraint. If the value
 * is negative then the constraint is currently violated.
 *
 * This function requires that [u] and [v] are in [graph] and they both have a
 * `rank` attribute.
 */
num slack(BaseGraph graph, u, v, minLen) {
  return (graph.node(u)['rank'] - graph.node(v)['rank']).abs() - minLen;
}
