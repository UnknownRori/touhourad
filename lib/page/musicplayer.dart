import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:touhourad/models/song.dart';
import 'package:touhourad/touhourad/touhourad.dart';

class MusicPlayer extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _MusicPlayerState();
}

class _MusicPlayerState extends State<MusicPlayer> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  Duration _duration = Duration();
  Duration _position = Duration();

  TouhouRad api = TouhouRad();
  Song? currentSong;
  TouhouFilterSong filter = TouhouFilterSong(
    pc98: true,
    classical: true,
    earlymodern: true,
    modern: true,
    popular: true,
  );

  bool isPlaying = false;

  @override
  void initState() {
    super.initState();
    try {
      _fetchMusic();
      _initAudioPlayer();
    } catch (e) {
      print("Shit");
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _positionSubscription?.cancel();
    _durationSubscription?.cancel();
    super.dispose();
  }

  void _initAudioPlayer() {
    // Listen for changes in audio position
    _positionSubscription = _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        _position = p;
      });
    });

    // Listen for audio duration
    _durationSubscription = _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _duration = d;
      });
    });
  }

  Future<void> _playMusic() async {
    if (isPlaying || currentSong == null) {
      return;
    }
    await _audioPlayer.play(UrlSource(currentSong!.songUrl));
    setState(() {
      isPlaying = true;
    });
  }

  Future<void> _stopMusic() async {
    await _audioPlayer.stop();
    setState(() {
      isPlaying = false;
    });
  }

  Future<void> _fetchMusic() async {
    Song song = await api.fetch(filter);
    setState(() {
      currentSong = song;
    });
  }

  Future<void> _nextMusic() async {
    _stopMusic();
    _fetchMusic();
    _playMusic();
  }

  void _seekMusic(double value) {
    final position = value * _duration.inMilliseconds;
    _audioPlayer.seek(Duration(milliseconds: position.toInt()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: currentSong != null
              ? [
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(currentSong!.imgBg),
                        fit: BoxFit
                            .cover, // This makes the image span the entire page
                      ),
                    ),
                  ),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Card(
                            color: Colors.black.withOpacity(0.8),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: CachedNetworkImage(
                                        imageUrl: currentSong!.imgMain),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    currentSong!.author,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    currentSong!.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Slider(
                                    value: (_position.inSeconds.toDouble() <=
                                            _duration.inSeconds.toDouble()
                                        ? _position.inSeconds.toDouble()
                                        : 0),
                                    max: _duration.inSeconds.toDouble(),
                                    onChanged: (value) {
                                      _seekMusic(value);
                                    },
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          if (!isPlaying) {
                                            _playMusic();
                                          }
                                        },
                                        icon: AnimatedSwitcher(
                                          duration: const Duration(
                                              milliseconds: 1000),
                                          transitionBuilder: (Widget child,
                                              Animation<double> animation) {
                                            return FadeTransition(
                                                opacity: animation,
                                                child: child);
                                          },
                                          key: ValueKey<bool>(isPlaying),
                                          child: isPlaying
                                              ? const Icon(
                                                  Icons.pause,
                                                  color: Colors.white,
                                                )
                                              : const Icon(
                                                  Icons.play_arrow,
                                                  color: Colors.white,
                                                ),
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          _nextMusic();
                                        },
                                        icon: const Icon(Icons.fast_forward,
                                            color: Colors.white),
                                      ),
                                      IconButton(
                                        onPressed: () {},
                                        icon: const Icon(Icons.filter_alt,
                                            color: Colors.white),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ]
              : [const Center(child: const CircularProgressIndicator())],
        ),
      ),
    );
  }
}
