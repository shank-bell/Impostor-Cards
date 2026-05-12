import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'game_screen.dart';

class LobbyScreen extends StatefulWidget {
  final String roomId;
  final String playerName;
  final bool isHost;
  final int playerCount;
  final int impostorCount;

  const LobbyScreen({
    super.key,
    required this.roomId,
    required this.playerName,
    required this.isHost,
    this.playerCount = 3,
    this.impostorCount = 1,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _players = [];
  late RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _loadPlayers();
    _subscribeToChanges();
  }

  Future<void> _loadPlayers() async {
    final players = await supabase
        .from('players')
        .select()
        .eq('room_id', widget.roomId);
    setState(() => _players = List<Map<String, dynamic>>.from(players));
  }

  void _subscribeToChanges() {
    _channel = supabase.channel('room_${widget.roomId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'players',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: widget.roomId,
        ),
        callback: (payload) => _loadPlayers(),
      )
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'rooms',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'id',
          value: widget.roomId,
        ),
        callback: (payload) {
          if (payload.newRecord['status'] == 'started') {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => GameScreen(
                  roomId: widget.roomId,
                  playerName: widget.playerName,
                ),
              ),
            );
          }
        },
      )
      .subscribe();
  }

  List<String> _getWordsForTopic(String topic) {
    final topics = {
      'Cricket': ['Virat Kohli', 'Rohit Sharma', 'MS Dhoni', 'Sachin Tendulkar', 'IPL', 'World Cup', 'Yorker', 'Test Match'],
      'Movies': ['Bahubali', 'Pushpa', 'Avengers', 'Shah Rukh Khan', 'Interstellar', 'Inception', 'KGF', 'Rajinikanth'],
      'Countries': ['India', 'Japan', 'Paris', 'Taj Mahal', 'Mount Everest', 'London', 'China', 'Australia'],
      'Food': ['Biryani', 'Pizza', 'Burger', 'Dosa', 'Ice Cream', 'Pasta', 'Mango', 'Chocolate'],
      'Technology': ['Artificial Intelligence', 'Flutter', 'Android', 'Python', 'Laptop', 'Cloud Computing', 'Firebase', 'Cyber Security'],
      'Sports': ['Football', 'Messi', 'Olympics', 'Basketball', 'Badminton', 'Ronaldo', 'Tennis', 'FIFA'],
      'Animals': ['Lion', 'Tiger', 'Elephant', 'Peacock', 'Dolphin', 'Eagle', 'Panda', 'Zebra'],
      'General Knowledge': ['Sun', 'School', 'Internet', 'Mobile', 'Railway', 'Festival', 'Music', 'Library'],
      'Anime': ['Naruto', 'One Piece', 'Doraemon', 'Shinchan', 'Pikachu', 'Dragon Ball', 'Attack on Titan', 'Pokemon'],
      'Games': ['PUBG', 'Minecraft', 'Free Fire', 'PlayStation', 'GTA', 'Mario', 'Valorant', 'Call of Duty'],
    };
    return topics[topic] ?? topics['Cricket']!;
  }

  Future<void> _startGame() async {
    if (_players.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 3 players!')),
      );
      return;
    }

    final room = await supabase
        .from('rooms')
        .select()
        .eq('id', widget.roomId)
        .single();

    final words = _getWordsForTopic(room['topic'] ?? 'Cricket');
    final random = DateTime.now().millisecondsSinceEpoch;
    final word = words[random % words.length];

    // Shuffle players and assign roles
    final shuffledPlayers = List<Map<String, dynamic>>.from(_players)..shuffle();
    
    for (int i = 0; i < shuffledPlayers.length; i++) {
      final isImpostor = i < widget.impostorCount;
      await supabase.from('players').update({
        'is_impostor': isImpostor,
      }).eq('id', shuffledPlayers[i]['id']);
      await Future.delayed(const Duration(milliseconds: 300));
    }

    await supabase.from('rooms').update({
      'status': 'started',
      'word': word,
    }).eq('id', widget.roomId);
  }

  @override
  void dispose() {
    _channel.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: const Text('Lobby', style: TextStyle(fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF7C4DFF), Color(0xFF3D5AFE)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Text('ROOM CODE',
                      style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 2)),
                  const SizedBox(height: 8),
                  Text(
                    widget.roomId,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 10,
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: widget.roomId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Code copied!')),
                      );
                    },
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.copy, color: Colors.white54, size: 16),
                        SizedBox(width: 4),
                        Text('Tap to copy',
                            style: TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('PLAYERS',
                    style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 2)),
                Text('${_players.length}/${widget.playerCount}',
                    style: const TextStyle(color: Color(0xFF7C4DFF), fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: _players.length,
                itemBuilder: (context, index) {
                  final player = _players[index];
                  final colors = [
                    const Color(0xFF7C4DFF),
                    const Color(0xFF00BCD4),
                    const Color(0xFFE53935),
                    const Color(0xFF43A047),
                    const Color(0xFFFB8C00),
                  ];
                  final color = colors[index % colors.length];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: color,
                          child: Text(
                            player['name'][0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(player['name'],
                            style: const TextStyle(color: Colors.white, fontSize: 16)),
                        if (player['is_host'] == true) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE53935),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text('HOST',
                                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            if (widget.isHost)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _startGame,
                  icon: const Icon(Icons.sports_esports),
                  label: const Text('START GAME',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF43A047),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF7C4DFF), strokeWidth: 2),
                    SizedBox(width: 12),
                    Text('Waiting for host to start...',
                        style: TextStyle(color: Colors.white54)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}