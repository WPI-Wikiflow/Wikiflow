import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:fuzzywuzzy/model/extracted_result.dart';

class WikiNode {
  List<double> vector = [];
  String title = "";
  String text = "";
  String id = "";
}

class WikiHelper {
  // The CSV is in the from of:
  // 0: vector 1 - 300 separated by spaces
  // 1: Title
  // 2: id
  // 3: Text of the document
  List<List<double>> vectors = [];
  List<String> titles = [];
  List<String> texts = [];
  List<String> ids = [];
  // Dictionary of titles to wikiNodes
  Map<String, WikiNode> wikiNodes = {};
  String wikiDataCSVPath = "";
  List<List> wikiData = [];

  WikiHelper(String CSVPath) {
    wikiDataCSVPath = CSVPath;
  }

  Future loadWikiData() async {
    wikiData = await csvToList(wikiDataCSVPath);
    // Print the first 5 rows of the CSV
    // wikiData.then((value) {
    vectors = getVectors(wikiData);
    titles = getTitles(wikiData);
    texts = getTexts(wikiData);
    ids = getIds(wikiData);
    wikiNodes = getWikiNodes(vectors, titles, texts, ids);
    if (kDebugMode) {
      print(vectors.sublist(0, 5));
      print(titles.sublist(0, 5));
      print(texts.sublist(0, 5));
      print(ids.sublist(0, 5));
    }
  }

  Future<List<List>> csvToList(String path) async {
    List<List<dynamic>> csvData = [];
    // Get test.csv from assets while being compatible with web
    String csvString = await rootBundle.loadString(path);
    List<String> csvRows = csvString.split('\n');
    for (String row in csvRows) {
      List<dynamic> rowData = row.split(',');
      csvData.add(rowData);
    }
    return csvData;
  }

  List<List<double>> getVectors(List<List<dynamic>> wikiData) {
    List<List<double>> vectors = [];
    for (List<dynamic> row in wikiData) {
      List<double> vector = [];
      for (String value in row[0].split(' ')) {
        vector.add(double.parse(value));
      }
      vectors.add(vector);
    }
    return vectors;
  }

  List<String> getTitles(List<List<dynamic>> wikiData) {
    List<String> titles = [];
    for (List<dynamic> row in wikiData) {
      titles.add(row[1]);
    }
    return titles;
  }

  List<String> getIds(List<List<dynamic>> wikiData) {
    List<String> ids = [];
    for (List<dynamic> row in wikiData) {
      ids.add(row[2]);
    }
    return ids;
  }

  List<String> getTexts(List<List<dynamic>> wikiData) {
    List<String> texts = [];
    for (List<dynamic> row in wikiData) {
      texts.add(row[3]);
    }
    return texts;
  }

  WikiNode getRandomNode() {
    Random r = Random();
    int randomIndex = r.nextInt(wikiData.length);
    return wikiNodes[titles[randomIndex]] ?? WikiNode();
  }

  Map<String, WikiNode> getWikiNodes(List<List<double>> vectors,
      List<String> titles, List<String> texts, List<String> ids) {
    Map<String, WikiNode> wikiNodes = {};
    for (int i = 0; i < vectors.length; i++) {
      WikiNode wikiNode = WikiNode();
      wikiNode.vector = vectors[i];
      wikiNode.title = titles[i];
      wikiNode.text = texts[i];
      wikiNode.id = ids[i];
      wikiNodes[wikiNode.title] = wikiNode;
    }
    return wikiNodes;
  }

  double getCosineSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    normA = sqrt(normA);
    normB = sqrt(normB);
    return dotProduct / (normA * normB);
  }

  List<String> getIndexOfNMostSimilar(List<double> vector, int n) {
    List<double> similarities = [];
    if (kDebugMode) {
      print(vectors);
    }
    for (List<double> v in vectors) {
      if (kDebugMode) {
        print(v);
      }
      similarities.add(getCosineSimilarity(vector, v));
    }
    if (kDebugMode) {
      print(similarities);
    }
    List<String> titlesOut = [];
    for (int i = 0; i < n; i++) {
      int index = 0;
      double bestValue = similarities.reduce(max);
      for (int j = 0; j < similarities.length; j++) {
        if (similarities[j] == bestValue) {
          index = j;
        }
      }

      if (kDebugMode) {
        print(index);
        print(similarities.reduce(max));
      }
      if (index != -1) {
        if (vector == vectors[index]) {
          similarities[index] = -1;
          i--;
        } else {
          titlesOut.add(titles[index]);
          similarities[index] = -1;
        }
      }
    }
    return titlesOut;
  }

  String indexOfFuzzyMatch(String query) {
    ExtractedResult<String> bestMatch =
        extractOne(query: query, choices: titles, cutoff: 5);
    return bestMatch.choice;
  }
}
