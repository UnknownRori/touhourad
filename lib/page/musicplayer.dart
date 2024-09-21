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
  bool isMuted = false;
  double _volume = 1.0;

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
    _positionSubscription = _audioPlayer.onPositionChanged.listen((Duration p) {
      setState(() {
        _position = p;
      });
    });

    _durationSubscription = _audioPlayer.onDurationChanged.listen((Duration d) {
      setState(() {
        _duration = d;
      });
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      _fetchMusic();
      _playMusic();
    });
  }

  Future<void> _playMusic() async {
    if (isPlaying || currentSong == null) {
      return;
    }
    await _audioPlayer.play(UrlSource(currentSong!.songUrl),
        position: _position);
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

  Future<void> _seekVolume() async {
    if (isMuted) {
      await _audioPlayer.setVolume(0);
      return;
    }
    await _audioPlayer.setVolume(_volume);
  }

  Future<void> _fetchMusic() async {
    Song song = await api.fetch(filter);
    _audioPlayer.play(UrlSource(song.songUrl));
    _audioPlayer.stop();
    _audioPlayer.seek(const Duration(milliseconds: 0));
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

  String _positionText() {
    final minutes =
        _position.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _position.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  String _durationText() {
    final minutes =
        _duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds =
        _duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
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
                                  const SizedBox(height: 24),
                                  Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _positionText(),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          _durationText(),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ]),
                                  Slider(
                                    value: _position.inSeconds.toDouble(),
                                    max: _duration.inSeconds.toDouble(),
                                    onChanged: (value) {
                                      setState(() {
                                        _position =
                                            Duration(seconds: value.toInt());
                                      });
                                    },
                                    onChangeEnd: (value) {
                                      _audioPlayer.seek(
                                          Duration(seconds: value.toInt()));
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            onPressed: () {
                                              if (!isPlaying) {
                                                _playMusic();
                                              } else {
                                                _stopMusic();
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
                                      Expanded(
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          children: [
                                            IconButton(
                                              onPressed: () {
                                                setState(() {
                                                  isMuted = !isMuted;
                                                  _seekVolume();
                                                });
                                              },
                                              icon: AnimatedSwitcher(
                                                duration: const Duration(
                                                    milliseconds: 1000),
                                                transitionBuilder:
                                                    (Widget child,
                                                        Animation<double>
                                                            animation) {
                                                  return FadeTransition(
                                                      opacity: animation,
                                                      child: child);
                                                },
                                                key: ValueKey<bool>(!isMuted),
                                                child: !isMuted
                                                    ? const Icon(
                                                        Icons.volume_up,
                                                        color: Colors.white,
                                                      )
                                                    : const Icon(
                                                        Icons.volume_mute,
                                                        color: Colors.white,
                                                      ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Slider(
                                                value: _volume,
                                                max: 1.0,
                                                onChanged: (value) {
                                                  setState(() {
                                                    setState(() {
                                                      _volume = value;
                                                      _seekVolume();
                                                    });
                                                  });
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
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
