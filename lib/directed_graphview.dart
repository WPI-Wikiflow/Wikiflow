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
                  if (text != "") {
                    _articleSearch = wikiHelper.indexOfFuzzyMatch(text);
                  } else {
                    _articleSearch = "";
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
                  WikiNode node =
                      wikiHelper.wikiNodes[_articleSearch] ?? WikiNode();
                  _articleSearch = node.title;
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
            print('tapped ${i.title}');
            print('tapped ${i.text}');
          }
          _selectedArticle = i;
          // Find the nodes that are connected to this node
          // and add them to the graph
          final List<Node> nodes = [];
          final List<Edge> edges = [];
          nodes.add(Node.Id(i));
          var mostSimilar =
              wikiHelper.getIndexOfNMostSimilar(_selectedArticle.vector, 3);
          if (kDebugMode) {
            print(mostSimilar);
          }
          for (var i in mostSimilar) {
            articleTitlesToNodes[wikiHelper.wikiNodes[i]?.title ?? ""] =
                wikiHelper.wikiNodes[i] ?? WikiNode();
            // edges.add(Edge(nodes[0], nodes[nodes.length - 1]));
            graph.addEdge(
                Node.Id(_selectedArticle), Node.Id(wikiHelper.wikiNodes[i]));
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
        child: Text('Node ${i!.title}'),
      ),
    );
  }

  WikiHelper wikiHelper = WikiHelper("/assets/test.csv");
  Graph graph = Graph();
  Algorithm? builder;
  String _articleSearch = "";
  Map<String, WikiNode> articleTitlesToNodes = {};
  // WikiNode _selectedNode = WikiNode();

  void initGraphWithNode(WikiNode rootNode) {
    // deep copy the graph
    List<Edge> edges = graph.edges;
    for (var edge in edges) {
      graph.removeEdge(edge);
    }
    List<Node> nodes = graph.nodes;
    for (var node in nodes) {
      graph.removeNode(node);
    }
    if (kDebugMode) {
      print("Graph cleared");
    }

    setState(() {
      List<Node> nodes = [];
      nodes.add(Node.Id(rootNode));
      // Get the 3 most similar titles to the random title
      var mostSimilar = wikiHelper.getIndexOfNMostSimilar(rootNode.vector, 3);

      // Add the most similar titles to the graph
      for (var i in mostSimilar) {
        nodes.add(Node.Id(wikiHelper.wikiNodes[i]));
        articleTitlesToNodes = {};
        articleTitlesToNodes[wikiHelper.wikiNodes[i]?.title ?? ""] =
            wikiHelper.wikiNodes[i] ?? WikiNode();
        graph.addEdge(nodes[0], nodes[nodes.length - 1]);
      }
      // Set builder
      builder = FruchtermanReingoldAlgorithm(iterations: 1000);
      graph = graph;
      builder = builder;
    });
  }

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
}
