import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:touhourad/models/song.dart';
import 'package:touhourad/touhourad/touhourad.dart';

class MusicPlayerMobile extends StatefulWidget {
  const MusicPlayerMobile({super.key});

  @override
  _MusicPlayerMobileState createState() => _MusicPlayerMobileState();
}

class _MusicPlayerMobileState extends State<MusicPlayerMobile> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  Duration _duration = const Duration();
  Duration _position = const Duration();

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
  bool showFilter = false;
  double _volume = 1.0;

  @override
  void initState() {
    super.initState();
    try {
      _fetchMusic();
      _initAudioPlayer();
    } catch (e) {
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'No internet connection',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      });
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
    try {
      Song song = await api.fetch(filter);

      _audioPlayer.play(UrlSource(song.songUrl));
      _audioPlayer.pause();
      _audioPlayer.seek(const Duration(milliseconds: 0));
      setState(() {
        currentSong = song;
      });
    } catch (e) {
      Future.delayed(Duration.zero, () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text(
              'No song available',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      });
    }
  }

  Future<void> _nextMusic() async {
    await _stopMusic();
    await _fetchMusic();
    await _playMusic();
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
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 1000),
                            transitionBuilder:
                                (Widget child, Animation<double> animation) {
                              return FadeTransition(
                                  opacity: animation, child: child);
                            },
                            child: !showFilter
                                ? Card(
                                    key: const Key("Player"),
                                    color: Colors.black.withOpacity(0.75),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(8.0),
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
                                                  MainAxisAlignment
                                                      .spaceBetween,
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
                                            value:
                                                _position.inSeconds.toDouble(),
                                            max: _duration.inSeconds.toDouble(),
                                            onChanged: (value) {
                                              setState(() {
                                                _position = Duration(
                                                    seconds: value.toInt());
                                              });
                                            },
                                            onChangeEnd: (value) {
                                              _audioPlayer.seek(Duration(
                                                  seconds: value.toInt()));
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
                                                      transitionBuilder:
                                                          (Widget child,
                                                              Animation<double>
                                                                  animation) {
                                                        return FadeTransition(
                                                            opacity: animation,
                                                            child: child);
                                                      },
                                                      key: ValueKey<bool>(
                                                          isPlaying),
                                                      child: isPlaying
                                                          ? const Icon(
                                                              Icons.pause,
                                                              color:
                                                                  Colors.white,
                                                            )
                                                          : const Icon(
                                                              Icons.play_arrow,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      _nextMusic();
                                                    },
                                                    icon: const Icon(
                                                        Icons.fast_forward,
                                                        color: Colors.white),
                                                  ),
                                                  IconButton(
                                                    onPressed: () {
                                                      setState(() {
                                                        showFilter = true;
                                                      });
                                                    },
                                                    icon: const Icon(
                                                        Icons.filter_alt,
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
                                                        duration:
                                                            const Duration(
                                                                milliseconds:
                                                                    1000),
                                                        transitionBuilder:
                                                            (Widget child,
                                                                Animation<
                                                                        double>
                                                                    animation) {
                                                          return FadeTransition(
                                                              opacity:
                                                                  animation,
                                                              child: child);
                                                        },
                                                        key: ValueKey<bool>(
                                                            !isMuted),
                                                        child: !isMuted
                                                            ? const Icon(
                                                                Icons.volume_up,
                                                                color: Colors
                                                                    .white,
                                                              )
                                                            : const Icon(
                                                                Icons
                                                                    .volume_mute,
                                                                color: Colors
                                                                    .white,
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
                                  )
                                : Card(
                                    key: const Key("Filter"),
                                    color: Colors.black.withOpacity(0.75),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              IconButton(
                                                onPressed: () => setState(() {
                                                  showFilter = false;
                                                }),
                                                icon: const Icon(
                                                    Icons.arrow_back,
                                                    color: Colors.white),
                                              ),
                                              const Text(
                                                "Back",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 16),
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: filter.pc98,
                                                onChanged: (val) =>
                                                    setState(() {
                                                  filter.pc98 = val!;
                                                }),
                                              ),
                                              const Text(
                                                "PC-98 era (Touhou 1 - 5)",
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 21,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: filter.classical,
                                                onChanged: (val) =>
                                                    setState(() {
                                                  filter.classical = val!;
                                                }),
                                              ),
                                              const Flexible(
                                                child: Text(
                                                  "Classical era (Touhou 6 - 9)",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 21,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: filter.earlymodern,
                                                onChanged: (val) =>
                                                    setState(() {
                                                  filter.earlymodern = val!;
                                                }),
                                              ),
                                              const Flexible(
                                                child: Text(
                                                  "Early Modern era (Touhou 10 - 12)",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 21,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: filter.modern,
                                                onChanged: (val) =>
                                                    setState(() {
                                                  filter.modern = val!;
                                                }),
                                              ),
                                              const Flexible(
                                                child: Text(
                                                  "Modern era (Touhou 13-17)",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 21,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          Row(
                                            children: [
                                              Checkbox(
                                                value: filter.popular,
                                                onChanged: (val) =>
                                                    setState(() {
                                                  filter.popular = val!;
                                                }),
                                              ),
                                              const Flexible(
                                                child: Text(
                                                  "Popular Only",
                                                  style: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 21,
                                                  ),
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
                      )
                    ],
                  ),
                ]
              : [const Center(child: CircularProgressIndicator())],
        ),
      ),
    );
  }
}
