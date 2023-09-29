import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class FontFetcher extends StatefulWidget {
  @override
  _FontFetcherState createState() => _FontFetcherState();
}

class _FontFetcherState extends State<FontFetcher> {
  final apiUrl =
      "https://www.googleapis.com/webfonts/v1/webfonts?key=AIzaSyBCHY2HjHbJvTjKpLe1VaxUApDXXXxp4l0";

  final Map<String, String> subsetMapping = {
    'arabic': 'Arabic',
    'bengali': 'Bengali',
    'chinese-hongkong': 'Chinese (Hong Kong)',
    'chinese-simplified': 'Chinese (Simplified)',
    'chinese-traditional': 'Chinese (Traditional)',
    'cyrillic': 'Cyrillic',
    'cyrillic-ext': 'Cyrillic Extended',
    'devanagari': 'Devanagari',
    'greek': 'Greek',
    'greek-ext': 'Greek Extended',
    'gujarati': 'Gujarati',
    'gurmukhi': 'Gurmukhi',
    'hebrew': 'Hebrew',
    'japanese': 'Japanese',
    'kannada': 'Kannada',
    'khmer': 'Khmer',
    'korean': 'Korean',
    'latin': 'Latin',
    'latin-ext': 'Latin Extended',
    'malayalam': 'Malayalam',
    'myanmar': 'Myanmar',
    'oriya': 'Oriya',
    'sinhala': 'Sinhala',
    'tamil': 'Tamil',
    'telugu': 'Telugu',
    'thai': 'Thai',
    'tibetan': 'Tibetan',
    'vietnamese': 'Vietnamese',
  };


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Font Fetcher'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: fetchAndSaveFonts,
              child: const Text('Fetch and Save Fonts'),
            ),
            const ElevatedButton(
              onPressed: downloadFonts,
              child: Text('Download Fonts'),
            ),
            const ElevatedButton(
              onPressed: createGoogleFontsJson,
              child: Text('Create GoogleFonts.json'),
            ),
          ],
        ),
      )
      ,
    );
  }

  Future<void> fetchAndSaveFonts() async {
    final response = await http.get(Uri.parse(apiUrl));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List<dynamic> items = data['items'];
      final List<Map<String, dynamic>> transformedItems = [];

      for (final item in items) {
        final Map<String, dynamic> transformedItem = {};

        transformedItem['family'] = item['family'];
        transformedItem['category'] = item['category'];
        transformedItem['subsets'] = _getReadableSubsets(item['subsets']);

        final files = item['files'];
        if (files != null && files['regular'] != null) {
          transformedItem['url'] = files['regular'];
        }

        transformedItems.add(transformedItem);
      }

      final transformedData = {'fonts': transformedItems};
      final jsonString = json.encode(transformedData);

      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/linsFontAPI.json');
      await file.writeAsString(jsonString);
    } else {
      // Handle error case
      print('Failed to load fonts');
    }
  }

  List<String> _getReadableSubsets(List<dynamic> subsets) {
    return subsets
        .map((subset) => subsetMapping[subset] ?? subset)
        .cast<String>()
        .toList(growable: false);
  }

}
Future<void> downloadFonts() async {
  // Get the cache directory
  final directory = await getApplicationDocumentsDirectory();

  // Read the file
  final file = File('${directory.path}/linsFontAPI.json');
  if (!await file.exists()) {
    print('File does not exist!');
    return;
  }

  final jsonString = await file.readAsString();
  final data = json.decode(jsonString);
  final List<dynamic> fonts = data['fonts'];

  // Create the GoogleFonts directory if it doesn't exist
  final googleFontsDir = Directory('${directory.path}/GoogleFonts');
  if (!await googleFontsDir.exists()) {
    await googleFontsDir.create();
  }

  for (final font in fonts) {
    final url = font['url'];
    if (url != null) {
      // Extract filename from URL
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;

      // Download the font file
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final fontFile = File('${googleFontsDir.path}/$fileName');
        await fontFile.writeAsBytes(response.bodyBytes);
      } else {
        print('Failed to download font ${font['family']}');
      }
    }
  }
  print('Fonts downloaded successfully!');
}
Future<void> createGoogleFontsJson() async {
  final directory = await getApplicationDocumentsDirectory();
  final file = File('${directory.path}/linsFontAPI.json');
  if (!await file.exists()) {
    print('File does not exist!');
    return;
  }

  final jsonString = await file.readAsString();
  final data = json.decode(jsonString);
  final List<dynamic> fonts = data['fonts'];

  // Base URL to replace
  const baseUrl = 'https://raw.githubusercontent.com/linslouis/SampleClientServerTest/master/app/src/main/assets/Fonts/GoogleFonts/';

  for (final font in fonts) {
    final url = font['url'];
    if (url != null) {
      // Extract filename from URL
      final uri = Uri.parse(url);
      final fileName = uri.pathSegments.last;

      // Replace the URL in the font map
      font['url'] = '$baseUrl$fileName';
    }
  }

  final modifiedJsonString = json.encode(data);
  final googleFontsFile = File('${directory.path}/GoogleFonts.json');
  await googleFontsFile.writeAsString(modifiedJsonString);

  print('GoogleFonts.json created successfully!');
}

void main() => runApp(
  MaterialApp(
    home: FontFetcher(),
  ),
);
