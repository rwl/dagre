part of dagre.order.test;

initOrderTest() {
  group("initOrder", () {
    CDigraph g;

    setUp(() {
      g = new CDigraph();
      g.graph({});
    });

    test("sets order to 0 for the node in a singleton graph", () {
      g.addNode(1, { 'rank': 0 });
      initOrder(g);
      expect(g.node(1)['order'], equals(0));
    });

    test("sets order to 0 to nodes on multiple single-node layers", () {
      g.addNode(1, { 'rank': 0 });
      g.addNode(2, { 'rank': 1 });
      g.addNode(3, { 'rank': 2 });
      initOrder(g);
      expect(g.node(1)['order'], equals(0));
      expect(g.node(2)['order'], equals(0));
      expect(g.node(3)['order'], equals(0));
    });

    test("incrementally sets the order position for nodes on the same rank", () {
      g.addNode(1, { 'rank': 0 });
      g.addNode(2, { 'rank': 0 });
      g.addNode(3, { 'rank': 0 });
      initOrder(g);

      // There is no guarantee about what order gets assigned to what node, but
      // we can assert that the order values 0, 1, 2 were assigned.
      expect(g.nodes().map((u) { return g.node(u)['order']; }),
                         same([0, 1, 2]));
    });

    test("does not assign order to subgraphs", () {
      g.addNode(1, { 'rank': 0 });
      g.addNode(2, { 'rank': 0 });
      g.addNode("sg1", {});
      g.parent(1, "sg1");
      g.parent(2, "sg1");
      initOrder(g);
      expect(g.node("sg1"), isNot(contains("order")));
    });
  });
}