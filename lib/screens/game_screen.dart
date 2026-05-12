import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GameScreen extends StatefulWidget {
  final String roomId;
  final String playerName;

  const GameScreen({
    super.key,
    required this.roomId,
    required this.playerName,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _players = [];
  Map<String, dynamic>? _myPlayer;
  String _word = '';
  String _topic = '';
  bool _revealed = false;
  bool _votingStarted = false;
  bool _isLoading = true;
  String? _myVote;
  Map<String, String> _allVotes = {};
  String? _eliminated;
  int _votingTimeLeft = 60;
  late RealtimeChannel _channel;

  @override
  void initState() {
    super.initState();
    _loadGameData();
    _subscribeToChanges();
  }

  Future<void> _loadGameData() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 2));

    final room = await supabase
        .from('rooms')
        .select()
        .eq('id', widget.roomId)
        .single();

    final players = await supabase
        .from('players')
        .select()
        .eq('room_id', widget.roomId);

    final me = players.firstWhere(
      (p) => p['name'] == widget.playerName,
      orElse: () => {},
    );

    setState(() {
      _word = room['word'] ?? '';
      _topic = room['topic'] ?? '';
      _players = List<Map<String, dynamic>>.from(players);
      _myPlayer = Map<String, dynamic>.from(me);
      _isLoading = false;
    });
  }

  void _subscribeToChanges() {
    _channel = supabase.channel('game_${widget.roomId}')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'players',
        filter: PostgresChangeFilter(
          type: PostgresChangeFilterType.eq,
          column: 'room_id',
          value: widget.roomId,
        ),
        callback: (payload) {
          _loadAllVotes();
        },
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
          final status = payload.newRecord['status'];
          if (status == 'voting' && !_votingStarted) {
            setState(() {
              _votingStarted = true;
              _votingTimeLeft = 60;
            });
            _startTimer();
          }
          if (status == 'ended') {
            _loadAllVotes();
          }
        },
      )
      .subscribe();
  }

  Future<void> _loadAllVotes() async {
    final players = await supabase
        .from('players')
        .select()
        .eq('room_id', widget.roomId);

    Map<String, String> votes = {};
    for (var p in players) {
      if (p['voted_for'] != null && p['voted_for'].toString().isNotEmpty) {
        votes[p['name']] = p['voted_for'];
      }
    }

    setState(() {
      _players = List<Map<String, dynamic>>.from(players);
      _allVotes = votes;
    });

    // Check if all voted
    if (votes.length == _players.length && _eliminated == null) {
      _finishVoting();
    }
  }

  Future<void> _startVoting() async {
    await supabase.from('rooms').update({
      'status': 'voting',
    }).eq('id', widget.roomId);
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      setState(() => _votingTimeLeft--);
      if (_votingTimeLeft <= 0) {
        _finishVoting();
        return false;
      }
      return _votingStarted && _eliminated == null;
    });
  }

  Future<void> _castVote(String suspectName) async {
    if (_myVote != null) return;

    setState(() => _myVote = suspectName);

    await supabase.from('players').update({
      'voted_for': suspectName,
    }).eq('id', _myPlayer!['id']);

    await _loadAllVotes();
  }

  void _finishVoting() {
    if (_eliminated != null) return;

    Map<String, int> voteCounts = {};
    for (var vote in _allVotes.values) {
      voteCounts[vote] = (voteCounts[vote] ?? 0) + 1;
    }
    if (voteCounts.isEmpty) return;

    final eliminated = voteCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    setState(() => _eliminated = eliminated);
  }

  @override
  void dispose() {
    _channel.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _myPlayer == null) {
      return const Scaffold(
        backgroundColor: Color(0xFF0D0D1A),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF7C4DFF)),
              SizedBox(height: 16),
              Text('Loading game...', style: TextStyle(color: Colors.white54)),
            ],
          ),
        ),
      );
    }

    if (_eliminated != null) return _buildResultScreen();
    if (_votingStarted) return _buildVotingScreen();
    if (_revealed) return _buildDiscussionScreen();
    return _buildCardRevealScreen();
  }

  Widget _buildCardRevealScreen() {
    final isImpostor = _myPlayer!['is_impostor'] ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('YOUR CARD',
                          style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
                      Text(widget.playerName,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('🏏 $_topic',
                        style: const TextStyle(color: Colors.white, fontSize: 13)),
                  ),
                ],
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _revealed = true),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 280,
                  height: 360,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A2E),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF7C4DFF), width: 2),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C4DFF),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: const Icon(Icons.help, color: Colors.white, size: 36),
                      ),
                      const SizedBox(height: 16),
                      Text(widget.playerName,
                          style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      const Text('TAP TO REVEAL YOUR CARD',
                          style: TextStyle(color: Colors.white38, fontSize: 11, letterSpacing: 2)),
                      const SizedBox(height: 16),
                      const Icon(Icons.touch_app, color: Color(0xFF7C4DFF), size: 32),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              const Text('Only you can see your card',
                  style: TextStyle(color: Colors.white38, fontSize: 12)),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDiscussionScreen() {
    final isImpostor = _myPlayer!['is_impostor'] ?? false;
    final isHost = _myPlayer!['is_host'] ?? false;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('YOUR CARD',
                  style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
              const SizedBox(height: 8),
              // Show role card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isImpostor ? const Color(0xFFE53935) : const Color(0xFF43A047),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Text(isImpostor ? '🕵️ IMPOSTOR' : '✅ PLAYER',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (!isImpostor) ...[
                      const Text('SECRET WORD',
                          style: TextStyle(color: Colors.white70, fontSize: 11, letterSpacing: 2)),
                      const SizedBox(height: 4),
                      Text(_word,
                          style: const TextStyle(
                              color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ] else ...[
                      const Text('You don\'t know the word!\nBlend in and survive!',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text('Category: $_topic',
                          style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('DISCUSSION PHASE',
                  style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
              const SizedBox(height: 8),
              _buildRule('💬', 'Give Clues',
                  'Describe the secret word with a single word or short phrase.',
                  const Color(0xFF00BCD4)),
              const SizedBox(height: 8),
              _buildRule('🕵️', 'Find the Impostor',
                  'Pay attention to vague or wrong answers.',
                  const Color(0xFFE53935)),
              const SizedBox(height: 8),
              _buildRule('🎭', 'Blend In',
                  'If you\'re the impostor, listen carefully and survive!',
                  const Color(0xFFFB8C00)),
              const Spacer(),
              if (isHost)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _startVoting,
                    icon: const Icon(Icons.how_to_vote),
                    label: const Text('START VOTING',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE53935),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                      Text('Waiting for host to start voting...',
                          style: TextStyle(color: Colors.white54)),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVotingScreen() {
    final colors = [
      const Color(0xFF7C4DFF),
      const Color(0xFF00BCD4),
      const Color(0xFFE53935),
      const Color(0xFF43A047),
      const Color(0xFFFB8C00),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.how_to_vote, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('VOTING',
                              style: TextStyle(color: Colors.white54, fontSize: 11, letterSpacing: 2)),
                          Text('WHO IS THE IMPOSTOR?',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _votingTimeLeft < 10 ? const Color(0xFFE53935) : const Color(0xFF1A1A2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$_votingTimeLeft s',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: _allVotes.length / _players.length,
                backgroundColor: Colors.white12,
                valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFE53935)),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _myVote != null
                      ? const Color(0xFF43A047).withOpacity(0.15)
                      : const Color(0xFFE53935).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Text(_myVote != null ? '✅' : '👊', style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _myVote != null
                            ? 'You voted for $_myVote. Waiting for others...'
                            : 'Tap a player to vote them as impostor',
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: _players.length,
                  itemBuilder: (context, index) {
                    final player = _players[index];
                    final name = player['name'] as String;
                    final isMe = name == widget.playerName;
                    final hasVoted = _allVotes.containsKey(name);
                    final color = colors[index % colors.length];

                    return GestureDetector(
                      onTap: (_myVote == null && !isMe) ? () => _castVote(name) : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A2E),
                          borderRadius: BorderRadius.circular(12),
                          border: _myVote == name
                              ? Border.all(color: const Color(0xFFE53935), width: 2)
                              : null,
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: color,
                              child: Text(name[0].toUpperCase(),
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('$name${isMe ? " (You)" : ""}',
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                                if (hasVoted)
                                  const Text('Has voted',
                                      style: TextStyle(color: Color(0xFF43A047), fontSize: 12)),
                              ],
                            ),
                            const Spacer(),
                            if (hasVoted)
                              const Icon(Icons.check_circle, color: Color(0xFF43A047))
                            else if (isMe)
                              const Text('You', style: TextStyle(color: Colors.white38))
                            else if (_myVote == null)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE53935),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('VOTE',
                                    style: TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    final eliminatedPlayer = _players.firstWhere(
      (p) => p['name'] == _eliminated,
      orElse: () => {},
    );
    final wasImpostor = eliminatedPlayer['is_impostor'] ?? false;
    final impostors = _players
        .where((p) => p['is_impostor'] == true)
        .map((p) => p['name'])
        .join(', ');

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(wasImpostor ? '🎉' : '😈', style: const TextStyle(fontSize: 80)),
              const SizedBox(height: 16),
              Text(
                wasImpostor ? 'CREWMATES WIN!' : 'IMPOSTOR WINS!',
                style: TextStyle(
                  color: wasImpostor ? const Color(0xFF43A047) : const Color(0xFFE53935),
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text('$_eliminated was eliminated',
                  style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 8),
              Text(
                wasImpostor
                    ? '$_eliminated was the Impostor!'
                    : 'The Impostor was $impostors!',
                style: TextStyle(
                  color: wasImpostor ? const Color(0xFF43A047) : const Color(0xFFE53935),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text('The secret word was: $_word',
                  style: const TextStyle(color: Colors.white54, fontSize: 14)),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.popUntil(context, (route) => route.isFirst),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C4DFF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('PLAY AGAIN',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRule(String emoji, String title, String desc, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                Text(desc, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}