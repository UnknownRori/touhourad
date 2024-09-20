import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:touhourad/models/song.dart';

class TouhouFilterSong {
  final bool pc98;
  final bool classical;
  final bool earlymodern;
  final bool modern;
  final bool popular;

  TouhouFilterSong(
      {required this.pc98,
      required this.classical,
      required this.earlymodern,
      required this.modern,
      required this.popular});
}

class TouhouRad {
  // I will get my own server
  static const String url = "https://api.touhourad.io/GetInfo";

  Future<Song> fetch(TouhouFilterSong filter) async {
    final response = await http.post(Uri.parse(url), headers: {
      "Is_CollectionsPC98": filter.pc98.toString(),
      "Is_CollectionsClassical": filter.classical.toString(),
      "Is_CollectionsEarlyModern": filter.earlymodern.toString(),
      "Is_CollectionsModern": filter.modern.toString(),
      "Is_PopularOnly": filter.popular.toString(),
    });

    if (response.statusCode != 200) {
      throw Exception("Fail to get info");
    }

    final data = json.decode(response.body);
    return Song(
        title: data['title'],
        author: data['author'],
        imgMain: data['image_Main'],
        imgBg: data['image_Background'],
        songUrl: data['song']);
  }
}
