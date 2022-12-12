import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';
import 'package:dropdown_search/dropdown_search.dart';

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
          // Add search bar
          Expanded(
            child: builder != null
                ? InteractiveViewer(
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
                        WikiNode a = node.key!.value;
                        // Get the title
                        String title = a.title;
                        return rectangWidget(a);
                      },
                    ),
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          // Put text in a pretty box
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(color: Colors.blue, spreadRadius: 1),
              ],
              // Put a border around the box
              border: Border.all(
                color: Colors.primaries.first,
                width: 1,
              ),
            ),
            child: Text("Article:\n ${_selectedArticle.text}"),
          ),

        ],
      ),
    );
  }

  int n = 8;
  Random r = Random();
  WikiNode _selectedArticle = WikiNode();

  Widget rectangWidget(WikiNode? i) {
    return InkWell(
      onTap: () {
        setState(() {
          if (kDebugMode) {
            print('tapped ${i!.title}');
            print('tapped ${i.text}');
            _selectedArticle = i;
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
        child: Text('Node ${i!.title}'),
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
      WikiNode randomNode = wikiHelper.getRandomNode();
      _selectedArticle = randomNode;

      final List<Node> nodes = [];
      final List<Edge> edges = [];

      // Get the index of the random title
      // var randomTitleIndex = wikiHelper.wikiNodes.indexOf(randomTitle);

      nodes.add(Node.Id(randomNode));

      // Get the 3 most similar titles to the random title
      var mostSimilar = wikiHelper.getIndexOfNMostSimilar(randomNode.vector, 3);

      // Add the most similar titles to the graph
      for (var i in mostSimilar) {
        nodes.add(Node.Id(wikiHelper.wikiNodes[i]));
        // edges.add(Edge(nodes[0], nodes[nodes.length - 1]));
        graph.addEdge(nodes[0], nodes[nodes.length - 1]);
      }
      // Set builder
      builder = FruchtermanReingoldAlgorithm(iterations: 1000);
      // Update state
      setState(() {});
    });
  }
}
