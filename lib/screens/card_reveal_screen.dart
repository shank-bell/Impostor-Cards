import 'package:flutter/material.dart';
import '../models/game_model.dart';
import 'role_card_screen.dart';

class CardRevealScreen extends StatefulWidget {
  final List<PlayerCard> cards;

  const CardRevealScreen({super.key, required this.cards});

  @override
  State<CardRevealScreen> createState() => _CardRevealScreenState();
}

class _CardRevealScreenState extends State<CardRevealScreen> {
  int _currentIndex = 0;

  void _revealCard() async {
    final card = widget.cards[_currentIndex];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RoleCardScreen(card: card),
      ),
    );

    if (_currentIndex < widget.cards.length - 1) {
      setState(() => _currentIndex++);
    } else {
      // All cards revealed, go back to home
      if (mounted) {
        _showGameStartDialog();
      }
    }
  }

  void _showGameStartDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF16213E),
        title: const Text(
          'Game Start!',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'All players have seen their roles. The game can begin!\n\nImpostors, blend in. Crewmates, find the impostors!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Let\'s Play!',
                style: TextStyle(color: Color(0xFFC51111))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.cards.length - _currentIndex;
    final playerName = widget.cards[_currentIndex].playerName;

    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Progress
              Text(
                'Card ${_currentIndex + 1} of ${widget.cards.length}',
                style: const TextStyle(color: Colors.white54, fontSize: 14),
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (_currentIndex + 1) / widget.cards.length,
                backgroundColor: Colors.white12,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFFC51111)),
              ),
              const Spacer(),

              // Player prompt
              const Icon(Icons.person_pin, color: Colors.white38, size: 64),
              const SizedBox(height: 20),
              Text(
                'Pass the device to',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                playerName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF16213E),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.privacy_tip_outlined,
                        color: Colors.white38),
                    const SizedBox(height: 8),
                    Text(
                      'Make sure only $playerName can see the screen when you tap below.',
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Reveal Button
              SizedBox(
                width: double.infinity,
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _revealCard,
                  icon: const Icon(Icons.visibility),
                  label: const Text(
                    'TAP TO REVEAL YOUR ROLE',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC51111),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '$remaining player${remaining == 1 ? '' : 's'} remaining',
                style: const TextStyle(color: Colors.white38, fontSize: 12),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
