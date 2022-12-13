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
                  WikiNode node = wikiHelper.wikiNodes[_articleSearch] ?? WikiNode();
                  _articleSearch = node.title;
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

  Widget rectangWidget(WikiNode? targetNode) {
    return InkWell(
      onTap: () {
        setState(() {
          if (kDebugMode) {
            print('tapped ${targetNode.title}');
            print('tapped ${targetNode.text}');
          }
          _selectedArticle = targetNode;
          var mostSimilar = wikiHelper.getIndexOfNMostSimilar(_selectedArticle.vector, 3);
          if (kDebugMode) {
            print(mostSimilar);
          }
          Node nodeNodeTarget = Node.Id(targetNode);
          nodes.add(nodeNodeTarget);
          for (var artTmp in mostSimilar) {
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
        child: Text('Node ${targetNode!.title}'),
      ),
    );
  }

  WikiHelper wikiHelper = WikiHelper("assets/test.csv");
  Graph graph = Graph();
  Algorithm? builder;
  String _articleSearch = "";

  List<Edge> edges = [];
  List<Node> nodes = [];

  void initGraphWithNode(WikiNode rootNode) {

    List<Edge> edges_tmp = graph.edges;
    if (kDebugMode) {
      print(edges_tmp);
    }
    graph.removeEdges(edges);
    if (kDebugMode) {
      print(graph.edges);
    }
    List<Node> nodes_tmp = graph.nodes;
    graph.removeNodes(nodes);
    graph.notifyGraphObserver();



      if (kDebugMode) {
        print("Graph cleared");
      }
      // graph.notifyGraphObserver();
      nodes = [Node.Id(rootNode)];
      // Get the 3 most similar titles to the random title
      var mostSimilar = wikiHelper.getIndexOfNMostSimilar(rootNode.vector, 3);

      // Add the most similar titles to the graph
      for (var i in mostSimilar) {
        Node node_tmp = Node.Id(wikiHelper.wikiNodes[i]);
        nodes.add(node_tmp);
        edges.add(Edge(nodes[0], nodes[nodes.length - 1]));
        // articleTitlesToNodes = {};
        // articleTitlesToNodes[wikiHelper.wikiNodes[i]?.title ?? ""] = wikiHelper.wikiNodes[i] ?? WikiNode();
        graph.addEdgeS(edges[edges.length - 1]);
      }
      // Set builder
      //
    setState(() {
      graph = graph;
      builder = FruchtermanReingoldAlgorithm(iterations: 1000);
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
