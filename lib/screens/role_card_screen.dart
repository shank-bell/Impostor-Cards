import 'dart:math';
import 'package:flutter/material.dart';
import '../models/game_model.dart';

class RoleCardScreen extends StatefulWidget {
  final PlayerCard card;

  const RoleCardScreen({super.key, required this.card});

  @override
  State<RoleCardScreen> createState() => _RoleCardScreenState();
}

class _RoleCardScreenState extends State<RoleCardScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isRevealed = false;
  bool _showFront = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _flipAnimation = Tween<double>(begin: 0, end: pi).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  void _revealRole() async {
    if (_isRevealed) return;
    setState(() => _isRevealed = true);

    _flipController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    setState(() => _showFront = true);
  }

  bool get _isImpostor => widget.card.role == CardRole.impostor;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        title: Text(widget.card.playerName,
            style: const TextStyle(color: Colors.white70)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            children: [
              const Spacer(),

              // Card flip area
              GestureDetector(
                onTap: _revealRole,
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value;
                    final isFront = angle >= pi / 2;

                    return Transform(
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      alignment: Alignment.center,
                      child: isFront ? _buildFront() : _buildBack(),
                    );
                  },
                ),
              ),

              const Spacer(),

              if (_showFront) ...[
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _isImpostor ? const Color(0xFFC51111) : const Color(0xFF117F2D),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'GOT IT — PASS THE PHONE',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                  ),
                ),
              ] else ...[
                const Text(
                  'TAP THE CARD TO REVEAL YOUR ROLE',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                    letterSpacing: 2,
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBack() {
    return Container(
      width: 260,
      height: 380,
      decoration: BoxDecoration(
        color: const Color(0xFF16213E),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white12, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('👾', style: TextStyle(fontSize: 80)),
          const SizedBox(height: 16),
          const Text(
            'IMPOSTOR\nCARDS',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white54,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white10,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'TAP TO REVEAL',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 11,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFront() {
    final bgColor = _isImpostor ? const Color(0xFFC51111) : const Color(0xFF117F2D);
    final emoji = _isImpostor ? '🔪' : '✅';
    final roleText = _isImpostor ? 'IMPOSTOR' : 'CREWMATE';
    final flavor = _isImpostor
        ? 'Sabotage and eliminate\nwithout getting caught!'
        : 'Complete your tasks and\nfind the Impostors!';

    return Transform(
      transform: Matrix4.identity()..rotateY(pi),
      alignment: Alignment.center,
      child: Container(
        width: 260,
        height: 380,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: bgColor.withOpacity(0.6),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Player color dot
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: widget.card.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white38, width: 1.5),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              widget.card.playerName,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 24),
            Text(emoji, style: const TextStyle(fontSize: 72)),
            const SizedBox(height: 16),
            Text(
              roleText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: 4,
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                flavor,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
