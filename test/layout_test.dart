import 'package:unittest/unittest.dart';

layoutTest() {
  group("layout", () {
    test("lays out out a graph with undefined node values", () {
      var inputGraph = new Digraph();
      inputGraph.addNode(1);
      var outputGraph = layout().run(inputGraph);
      expect(outputGraph.node(1), property("x"));
      expect(outputGraph.node(1), property("y"));
    });

    test("lays out out a graph with undefined edge values", () {
      var inputGraph = new Digraph();
      inputGraph.addNode(1);
      inputGraph.addNode(2);
      inputGraph.addEdge("A", 1, 2);
      var outputGraph = layout().run(inputGraph);
      expect(outputGraph.edge("A"), property("points"));
    });

    test("includes width and height information", () {
      var inputGraph = new Digraph();
      inputGraph.addNode(1, { width: 50, height: 20 });
      inputGraph.addNode(2, { width: 100, height: 30 });
      inputGraph.addEdge(null, 1, 2, {});

      var outputGraph = layout().run(inputGraph);

      expect(outputGraph.graph().width, equals(100));
      expect(outputGraph.graph().height, equals(20 + 30 + layout().rankSep()));
    });

    test("ranks nodes left-to-right with rankDir=LR", () {
      var inputGraph = new Digraph();
      inputGraph.addNode(1, { width: 1, height: 1 });
      inputGraph.addNode(2, { width: 1, height: 1 });
      inputGraph.addEdge(null, 1, 2);
      inputGraph.graph({ rankDir: "LR" });

      var outputGraph = layout().run(inputGraph);

      var n1X = outputGraph.node(1).x;
      var n2X = outputGraph.node(2).x;
      expect(n1X < n2X, isTrue,
                    reason: "Expected node 1 (" + n1X + ") to come before node 2 (" + n2X + ")");
      expect(outputGraph.node(1).y, equals(outputGraph.node(2).y));
    });

    test("ranks nodes right-to-left with rankDir=RL", () {
      var inputGraph = new Digraph();
      inputGraph.addNode(1, { width: 1, height: 1 });
      inputGraph.addNode(2, { width: 1, height: 1 });
      inputGraph.addEdge(null, 1, 2);
      inputGraph.graph({ rankDir: "RL" });

      var outputGraph = layout().run(inputGraph);

      var n1X = outputGraph.node(1).x;
      var n2X = outputGraph.node(2).x;
      expect(n1X > n2X, isTrue,
                    reason: "Expected node 1 (" + n1X + ") to come after node 2 (" + n2X + ")");
      expect(outputGraph.node(1).y, equals(outputGraph.node(2).y));
    });


    // This test is necessary until we drop layout().rankDir(...)
    test("produces the same output for rankDir=LR input", () {
      var inputGraph = new Digraph();
      inputGraph.addNode(1, { width: 1, height: 1 });
      inputGraph.addNode(2, { width: 1, height: 1 });
      var outputGraph1 = layout().rankDir("LR").run(inputGraph);

      inputGraph.graph({ rankDir: "LR" });
      var outputGraph2 = layout().run(inputGraph);

      expect(outputGraph1.node(1).x, equals(outputGraph2.node(1).x));
      expect(outputGraph1.node(2).x, equals(outputGraph2.node(2).x));
      expect(outputGraph1.node(1).y, equals(outputGraph2.node(1).y));
      expect(outputGraph1.node(2).y, equals(outputGraph2.node(2).y));
    });

    group("rank constraints", () {
      var g;

      setUp(() {
        g = new Digraph();
        g.addNode(1, { width: 1, height: 1 });
        g.addNode(2, { width: 1, height: 1, rank: "same_1" });
        g.addNode(3, { width: 1, height: 1, rank: "same_1" });
        g.addNode(4, { width: 1, height: 1 });
        g.addNode(5, { width: 1, height: 1, rank: "min" });
        g.addNode(6, { width: 1, height: 1, rank: "max" });

        g.addEdge(null, 1, 2);
        g.addEdge(null, 3, 4);
        g.addEdge(null, 6, 1);
      });

      test("ensures nodes with rank=min have the smallest y value", () {
        var out = layout().run(g);
        var minY = Math.min.apply(Math, out.nodes().map((u) { return out.node(u).y; }));
        expect(out.node(5), propertyVal("y", minY));
      });

      test("ensures nodes with rank=max have the greatest y value", () {
        var out = layout().run(g);
        var maxY = Math.max.apply(Math, out.nodes().map((u) { return out.node(u).y; }));
        expect(out.node(6), propertyVal("y", maxY));
      });

      test("ensures nodes with the rank=same_x have the same y value", () {
        var out = layout().run(g);
        expect(out.node(3).y, equals(out.node(2).y));
      });

      group("with rankDir=BT", () {
        setUp(() {
          g.graph({ rankDir: "BT" });
        });

        test("ensures nodes with rank=min have the largest y value", () {
          var out = layout().run(g);
          var maxY = Math.max.apply(Math, out.nodes().map((u) { return out.node(u).y; }));
          expect(out.node(5), propertyVal("y", maxY));
        });

        test("ensures nodes with rank=max have the smallest y value", () {
          var out = layout().run(g);
          var minY = Math.min.apply(Math, out.nodes().map((u) { return out.node(u).y; }));
          expect(out.node(6), propertyVal("y", minY));
        });
      });
    });
  });
}