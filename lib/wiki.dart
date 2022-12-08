import 'dart:ffi';
import 'dart:io';
import 'dart:math';

class WikiHelper {


  WikiHelper(String CSVPath) {
    String wikiDataCSVPath = CSVPath;
    List<List<dynamic>> wikiData = csvToList(wikiDataCSVPath);

  }

  // The CSV is in the from of:
  // 0: vector 1 - 300 separated by spaces
  // 1: Title
  // 2: id
  // 3: Text of the document

  List<List<dynamic>> csvToList(String path) {
    List<List<dynamic>> csvData = [];
    File file = File(path);
    String csvString = file.readAsStringSync();
    List<String> csvRows = csvString.split('\n');
    for (String row in csvRows) {
      List<dynamic> rowData = row.split(',');
      csvData.add(rowData);
    }
    return csvData;
  }

  List<List<Double>> getVectors(List<List<dynamic>> wikiData) {
    List<List<Double>> vectors = [];
    for (List<dynamic> row in wikiData) {
      List<Double> vector = [];
      for (String value in row[0].split(' ')) {
        vector.add(double.parse(value) as Double);
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

  double getCosinSimilarity(List<double> a, List<double> b) {
    double dotProduct = 0.0;
    double normA = 0.0;
    double normB = 0.0;
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return dotProduct / (normA * normB);
  }

  List<int> getIndexOfNMostSimilar(List<double> vector, List<List<double>> vectors, int n) {
    List<double> similarities = [];
    for (List<double> v in vectors) {
      similarities.add(getCosinSimilarity(vector, v));
    }
    List<int> indexes = [];
    for (int i = 0; i < n; i++) {
      indexes.add(similarities.indexOf(similarities.reduce(max)));
      similarities[indexes[i]] = -1;
    }
    return indexes;
  }
}
