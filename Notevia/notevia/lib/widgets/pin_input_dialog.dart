import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';

class PinInputDialog extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Function(String) onPinEntered;
  final bool isSetup;

  const PinInputDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.onPinEntered,
    this.isSetup = false,
  });

  static Future<bool> show(BuildContext context, {
    required String title,
    String? subtitle,
    bool isSetup = false,
    Function(String)? onPinEntered,
  }) async {
    bool result = false;
    await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinInputDialog(
        title: title,
        subtitle: subtitle,
        isSetup: isSetup,
        onPinEntered: onPinEntered ?? (pin) {
          result = true;
          Navigator.of(context).pop();
        },
      ),
    );
    return result;
  }

  @override
  State<PinInputDialog> createState() => _PinInputDialogState();
}

class _PinInputDialogState extends State<PinInputDialog>
    with TickerProviderStateMixin {
  String _pin = '';
  bool _isError = false;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _shakeAnimation = Tween<double>(
      begin: 0,
      end: 10,
    ).animate(CurvedAnimation(
      parent: _shakeController,
      curve: Curves.elasticIn,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: AnimatedBuilder(
        animation: _shakeAnimation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(_shakeAnimation.value, 0),
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_rounded,
                    size: 48,
                    color: _isError 
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (widget.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      widget.subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 32),
                  _buildPinDisplay(),
                  const SizedBox(height: 24),
                  _buildNumberPad(),
                  if (_isError) ...[
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.wrongPinCode,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPinDisplay() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(4, (index) {
        final isFilled = index < _pin.length;
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isFilled
                ? (_isError 
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.primary)
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            border: Border.all(
              color: _isError 
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumberPad() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [1, 2, 3].map((number) => _buildNumberButton(number.toString())).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [4, 5, 6].map((number) => _buildNumberButton(number.toString())).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [7, 8, 9].map((number) => _buildNumberButton(number.toString())).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 60), // Empty space
            _buildNumberButton('0'),
            _buildDeleteButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildNumberButton(String number) {
    return InkWell(
      onTap: () => _onNumberPressed(number),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Center(
          child: Text(
            number,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _onDeletePressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Icon(
          Icons.backspace_outlined,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
    );
  }

  void _onNumberPressed(String number) {
    if (_pin.length < 4) {
      setState(() {
        _pin += number;
        _isError = false;
      });
      
      if (_pin.length == 4) {
        _validatePin();
      }
    }
  }

  void _onDeletePressed() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
        _isError = false;
      });
    }
  }

  Future<void> _validatePin() async {
    if (widget.isSetup) {
      // For setup mode, just return the PIN
      widget.onPinEntered(_pin);
      return;
    }

    // For verification mode, check against stored PIN
    final prefs = await SharedPreferences.getInstance();
    final storedPin = prefs.getString('pin_code') ?? '';
    
    if (_pin == storedPin) {
      widget.onPinEntered(_pin);
    } else {
      setState(() {
        _isError = true;
        _pin = '';
      });
      _shakeController.forward().then((_) {
        _shakeController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  static Future<bool> show({
    required BuildContext context,
    required String title,
    String? subtitle,
    bool isSetup = false,
  }) async {
    bool result = false;
    
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PinInputDialog(
        title: title,
        subtitle: subtitle,
        isSetup: isSetup,
        onPinEntered: (pin) {
          result = true;
          Navigator.of(context).pop();
        },
      ),
    );
    
    return result;
  }
}