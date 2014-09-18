part of dagre.order;

/**
 * Given a graph with a set of layered nodes (i.e. nodes that have a `rank`
 * attribute) this function attaches an `order` attribute that uniquely
 * arranges each node of each rank. If no constraint graph is provided the
 * order of the nodes in each rank is entirely arbitrary.
 */
initOrder(BaseGraph g, [bool random=false]) {
  final layers = new SplayTreeMap<int, List>();

  g.eachNode((u, Map value) {
    if (/*g.children && */g.children(u).length > 0) return;
//    if (!value.containsKey('rank')) value['rank'] = -1;
    List layer = layers[value['rank']];
    if (layer == null) {
      layer = layers[value['rank']] = [];
    }
    layer.add(u);
  });

  layers.values.forEach((List layer) {
    if (random) {
      util.shuffle(layer);
    }
    int i = 0;
    layer.forEach((u) {
      g.node(u)['order'] = i;
      i++;
    });
  });

  final cc = crossCount(g);
  g.graph()['orderInitCC'] = cc;
  g.graph()['orderCC'] = double.MAX_FINITE;
}
