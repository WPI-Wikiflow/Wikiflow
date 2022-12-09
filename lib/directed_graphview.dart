import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'wiki.dart';
class GraphClusterViewPage extends StatefulWidget {
  const GraphClusterViewPage({super.key});

  @override
  _GraphClusterViewPageState createState() => _GraphClusterViewPageState();
}

class _GraphClusterViewPageState extends State<GraphClusterViewPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          Expanded(
            child: builder != null ?
    InteractiveViewer(
              constrained: false,
              boundaryMargin: const EdgeInsets.all(8),
              minScale: 0.001,
              maxScale: 100,
              child: GraphView(
                graph: graph,
                algorithm: builder!,
                paint: Paint()
                  ..color = Colors.green
                  ..strokeWidth = 1
                  ..style = PaintingStyle.fill,
                builder: (Node node) {
                  // I can decide what widget should be shown here based on the id
                  var a = node.key!.value;
                  return rectangWidget(a);
                },
              ),
            ) : const Center(child: CircularProgressIndicator()),
          ),
        ],
      ),
    );
  }

  int n = 8;
  Random r = Random();

  Widget rectangWidget(String? i) {
    return InkWell(
      onTap: () {
        setState(() {
          if (kDebugMode) {
            print('tapped $i');
            print("most similar: ${wikiHelper.getIndexOfNMostSimilar(wikiHelper.vectors[0], 3)}");
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          boxShadow: const [
            BoxShadow(color: Colors.blue, spreadRadius: 1),
          ],
        ),
        child: Text('Node $i'),
      ),
    );
  }

  WikiHelper wikiHelper = WikiHelper("test.csv");
  final Graph graph = Graph();
  Algorithm? builder;

  @override
  void initState() {
    super.initState();

    // Get random title from wikiHelper

    // Wait for wikiHelper to finish loading
    wikiHelper.loadWikiData().then((value) {
      if (kDebugMode) {
        print(wikiHelper.titles.length);
      }
      String randomTitle = wikiHelper.titles[r.nextInt(wikiHelper.titles.length)];

      final List<Node> nodes = [];
      final List<Edge> edges = [];

      // Get the index of the random title
      var randomTitleIndex = wikiHelper.titles.indexOf(randomTitle);

      nodes.add(Node.Id(randomTitle));

      // Get the 3 most similar titles to the random title
      var mostSimilar = wikiHelper.getIndexOfNMostSimilar(wikiHelper.vectors[randomTitleIndex], 3);

      // Add the most similar titles to the graph
      for (var i in mostSimilar) {
        nodes.add(Node.Id(wikiHelper.titles[i]));
        // edges.add(Edge(nodes[0], nodes[nodes.length - 1]));
        graph.addEdge(nodes[0], nodes[nodes.length - 1]);
      }
      // Set builder
      builder = FruchtermanReingoldAlgorithm(iterations: 1000);
      // Update state
      setState(() {
      });
    });
  }
}
