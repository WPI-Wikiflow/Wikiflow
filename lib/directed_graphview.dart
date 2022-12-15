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
  void initState() {
    super.initState();
    // Wait for wikiHelper to finish loading
    wikiHelper.loadWikiData().then((value) {
      if (kDebugMode) {
        print(wikiHelper.titles.length);
      }
      WikiNode randomNode = wikiHelper.getRandomNode();
      _selectedArticle = randomNode;

      initGraphWithNode(randomNode);
    });
  }

  Random r = Random();
  WikiNode _selectedArticle = WikiNode();
  WikiHelper wikiHelper = WikiHelper("assets/needDtoVFinalWithVectors2.csv");
  Graph graph = Graph();
  Algorithm? builder;
  String _articleSearch = "";

  List<Edge> edges = [];
  List<Node> nodes = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        children: [
          // Add search bar in normal text field
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: _articleSearch,
                hintText: "Search for an article",
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(25.0)),
                ),
              ), // Get the text as soon as the user types
              onChanged: (text) {
                setState(() {
                  // Update the text
                  if (text.length >= 2) {
                    _articleSearch = wikiHelper.indexOfFuzzyMatch(text);
                  }
                });
                if (kDebugMode) {
                  print(_articleSearch);
                }
              },
              onSubmitted: (text) {
                // Update the text
                if (text != "") {
                  _articleSearch = wikiHelper.indexOfFuzzyMatch(text);
                  WikiNode node = wikiHelper.wikiNodes[_articleSearch]!;
                  _selectedArticle = node;
                  initGraphWithNode(node);
                }
                if (kDebugMode) {
                  print(_articleSearch);
                }
              },
            ),
          ),
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
                        return rectangWidget(node.key!.value);
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

  Widget rectangWidget(WikiNode? targetNode) {
    return InkWell(
      onTap: () {
        setState(() {
          if (kDebugMode) {
            print('tapped ${targetNode.title}');
            print('tapped ${targetNode.text}');
          }
          _selectedArticle = targetNode;
          List<String> mostSimilar =
              wikiHelper.getIndexOfNMostSimilar(_selectedArticle.vector, 3);
          if (kDebugMode) {
            print(mostSimilar);
          }
          Node nodeNodeTarget = Node.Id(targetNode);
          nodes.add(nodeNodeTarget);
          for (String artTmp in mostSimilar) {
            Node destNode = Node.Id(wikiHelper.wikiNodes[artTmp]);
            nodes.add(destNode);
            Edge edge = Edge(nodeNodeTarget, destNode);
            edges.add(edge);
            graph.addEdgeS(edge);
          }
          // Set builder
          builder = FruchtermanReingoldAlgorithm(iterations: 1000);
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
        child: Text(targetNode!.title),
      ),
    );
  }

  void initGraphWithNode(WikiNode rootNode) {
    setState(() {
      // Reset the graph
      graph.removeEdges(edges);
      graph.removeNodes(nodes);
      // Clear the lists
      nodes = [];
      edges = [];

      // Add the root node
      Node centerNode = Node.Id(rootNode);
      nodes.add(centerNode);

      // Get the 3 most similar titles to the random title
      var mostSimilar = wikiHelper.getIndexOfNMostSimilar(rootNode.vector, 3);

      // Add the most similar titles to the graph
      for (var i in mostSimilar) {
        // Build the node
        Node nodeTmp = Node.Id(wikiHelper.wikiNodes[i]);
        nodes.add(nodeTmp);
        // Build the edge
        Edge edge = Edge(centerNode, nodeTmp);
        // Add the edge to the graph
        edges.add(edge);
        graph.addEdgeS(edge);
      }
      // Set builder
      builder = FruchtermanReingoldAlgorithm(iterations: 100);
    });
  }
}
