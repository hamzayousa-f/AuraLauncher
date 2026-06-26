import 'package:flutter/material.dart';

class BlockerView extends StatelessWidget {
  const BlockerView({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.02),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: SizedBox(
              width: 240,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.shield_rounded, size: 36, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  const Text(
                    'System Shield Blocker Engine',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Kernel intercept state active. Custom firewall rules ready for layout mapping.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}