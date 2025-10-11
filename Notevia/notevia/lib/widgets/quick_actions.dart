import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

class QuickActions extends StatefulWidget {
  final VoidCallback onNotePressed;
  final VoidCallback onVoicePressed;
  final VoidCallback onDiaryPressed;
  final VoidCallback? onNewNote;
  final VoidCallback? onVoiceNote;
  final VoidCallback? onNewDiary;

  const QuickActions({
    super.key,
    required this.onNotePressed,
    required this.onVoicePressed,
    required this.onDiaryPressed,
    this.onNewNote,
    this.onVoiceNote,
    this.onNewDiary,
  });

  @override
  State<QuickActions> createState() => _QuickActionsState();
}

class _QuickActionsState extends State<QuickActions>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 0.75,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
    if (_isExpanded) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        AnimatedBuilder(
          animation: _expandAnimation,
          builder: (context, child) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (_expandAnimation.value > 0) ...[
                  Transform.scale(
                    scale: _expandAnimation.value,
                    child: Opacity(
                      opacity: _expandAnimation.value,
                      child: _buildActionButton(
                        icon: Icons.book_outlined,
                        label: AppLocalizations.of(context)!.diary,
                        color: Colors.purple,
                        onPressed: () {
                          _toggleExpanded();
                          widget.onDiaryPressed();
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 12 * _expandAnimation.value),
                  Transform.scale(
                    scale: _expandAnimation.value,
                    child: Opacity(
                      opacity: _expandAnimation.value,
                      child: _buildActionButton(
                        icon: Icons.mic_rounded,
                        label: AppLocalizations.of(context)!.voiceNote,
                        color: Colors.orange,
                        onPressed: () {
                          _toggleExpanded();
                          widget.onVoicePressed();
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 12 * _expandAnimation.value),
                  Transform.scale(
                    scale: _expandAnimation.value,
                    child: Opacity(
                      opacity: _expandAnimation.value,
                      child: _buildActionButton(
                        icon: Icons.edit_note_rounded,
                        label: AppLocalizations.of(context)!.note,
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {
                          _toggleExpanded();
                          widget.onNotePressed();
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: 12 * _expandAnimation.value),
                ],
              ],
            );
          },
        ),
        FloatingActionButton(
          onPressed: _toggleExpanded,
          child: AnimatedBuilder(
            animation: _rotationAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _rotationAnimation.value * 2 * 3.14159,
                child: Icon(
                  _isExpanded ? Icons.close : Icons.add,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          mini: true,
          backgroundColor: color,
          foregroundColor: Colors.white,
          onPressed: onPressed,
          heroTag: label,
          child: Icon(icon),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}