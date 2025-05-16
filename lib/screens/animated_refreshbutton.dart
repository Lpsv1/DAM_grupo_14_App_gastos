import 'package:flutter/material.dart';

class AnimatedRefreshButton extends StatefulWidget {
  final VoidCallback onPressed;

  const AnimatedRefreshButton({Key? key, required this.onPressed})
    : super(key: key);

  @override
  _AnimatedRefreshButtonState createState() => _AnimatedRefreshButtonState();
}

class _AnimatedRefreshButtonState extends State<AnimatedRefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
  }

  void _handlePress() {
    _controller.forward(from: 0.0);
    widget.onPressed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: Tween(begin: 0.0, end: 1.0).animate(_controller),
      child: IconButton(
        icon: const Icon(
          Icons.refresh,
          color: Colors.white,
          size: 28,
          shadows: [
            Shadow(blurRadius: 8, color: Colors.white, offset: Offset(0, 0)),
          ],
        ),
        onPressed: _handlePress,
      ),
    );
  }
}
