import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math';
import 'lobby_screen.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  int _step = 0;
  int _playerCount = 3;
  String _selectedTopic = 'Cricket';
  int _impostorCount = 1;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _topics = [
    {'name': 'Cricket', 'emoji': '🏏'},
    {'name': 'Movies', 'emoji': '🎬'},
    {'name': 'Countries', 'emoji': '🌍'},
    {'name': 'Food', 'emoji': '🍕'},
    {'name': 'Technology', 'emoji': '💻'},
    {'name': 'Sports', 'emoji': '⚽'},
    {'name': 'Animals', 'emoji': '🦁'},
    {'name': 'General Knowledge', 'emoji': '🎲'},
    {'name': 'Anime', 'emoji': '⚡'},
    {'name': 'Games', 'emoji': '🎮'},
  ];

  String _generateRoomCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return List.generate(6, (i) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> _createRoom() async {
    setState(() => _isLoading = true);
    try {
      final roomId = _generateRoomCode();
      final supabase = Supabase.instance.client;

      await supabase.from('rooms').insert({
        'id': roomId,
        'host_name': 'Host',
        'topic': _selectedTopic,
        'status': 'waiting',
      });

      await supabase.from('players').insert({
        'room_id': roomId,
        'name': 'Host',
        'is_host': true,
      });

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LobbyScreen(
              roomId: roomId,
              playerName: 'Host',
              isHost: true,
              playerCount: _playerCount,
              impostorCount: _impostorCount,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(
          _step == 0 ? 'Players' : _step == 1 ? 'Category' : 'Roles & Rules',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_step == 0) {
              Navigator.pop(context);
            } else {
              setState(() => _step--);
            }
          },
        ),
      ),
      body: Column(
        children: [
          // Progress bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: List.generate(3, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: const EdgeInsets.only(right: 4),
                    decoration: BoxDecoration(
                      color: i <= _step
                          ? const Color(0xFF7C4DFF)
                          : Colors.white12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'GAME SETUP',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 11,
                  letterSpacing: 2,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _step == 0
                ? _buildPlayersStep()
                : _step == 1
                    ? _buildCategoryStep()
                    : _buildRulesStep(),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_step < 2) {
                          setState(() => _step++);
                        } else {
                          _createRoom();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _step == 2
                      ? const Color(0xFF43A047)
                      : const Color(0xFF7C4DFF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(_step == 2
                              ? Icons.sports_esports
                              : Icons.arrow_forward),
                          const SizedBox(width: 8),
                          Text(
                            _step == 2 ? 'START GAME' : 'NEXT',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Number of Players',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C4DFF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Text(
                          '$_playerCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _playerCount.toDouble(),
                  min: 3,
                  max: 10,
                  divisions: 7,
                  activeColor: const Color(0xFF7C4DFF),
                  inactiveColor: Colors.white12,
                  onChanged: (v) => setState(() => _playerCount = v.toInt()),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('3', style: TextStyle(color: Colors.white54)),
                    Text('10', style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _playerCount,
              itemBuilder: (context, i) {
                final colors = [
                  const Color(0xFF7C4DFF),
                  const Color(0xFF00BCD4),
                  const Color(0xFFE53935),
                  const Color(0xFF43A047),
                  const Color(0xFFFB8C00),
                ];
                final color = colors[i % colors.length];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border(
                      left: BorderSide(color: color, width: 4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        '${i + 1}',
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Player ${i + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const Spacer(),
                      Icon(Icons.person, color: color),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryStep() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.2,
        ),
        itemCount: _topics.length,
        itemBuilder: (context, i) {
          final topic = _topics[i];
          final isSelected = _selectedTopic == topic['name'];
          return GestureDetector(
            onTap: () => setState(() => _selectedTopic = topic['name']),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF7C4DFF).withOpacity(0.3)
                    : const Color(0xFF1A1A2E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF7C4DFF)
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(topic['emoji'],
                      style: const TextStyle(fontSize: 36)),
                  const SizedBox(height: 8),
                  Text(
                    topic['name'],
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFF7C4DFF)
                          : Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Text('10 words',
                      style:
                          TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildRulesStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          // Impostors
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE53935), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🕵️', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text('Impostors',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const Text('Players who don\'t know the word',
                    style:
                        TextStyle(color: Colors.white54, fontSize: 13)),
                const SizedBox(height: 16),
                Center(
                  child: GestureDetector(
                    onTap: () {
                      if (_impostorCount < (_playerCount / 2).floor()) {
                        setState(() => _impostorCount++);
                      }
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          '$_impostorCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Voting mode
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00BCD4), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('🗳️', style: TextStyle(fontSize: 24)),
                    SizedBox(width: 8),
                    Text('Voting Mode',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.person, color: Colors.white54),
                            Text('Single Vote',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 12)),
                            Text('Host decides',
                                style: TextStyle(
                                    color: Colors.white38, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C4DFF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.group, color: Colors.white),
                            Text('Team Vote',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                            Text('All players',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}