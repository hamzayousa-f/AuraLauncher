import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../data/blocker_profile.dart';
import '../../../../core/services/launcher_service.dart';

class FluidFrictionOverlay extends StatefulWidget {
  final BlockerProfile profile;
  final VoidCallback onOverrideUnlocked;

  const FluidFrictionOverlay({super.key, required this.profile, required this.onOverrideUnlocked});

  @override
  State<FluidFrictionOverlay> createState() => _FluidFrictionOverlayState();
}

class _FluidFrictionOverlayState extends State<FluidFrictionOverlay> with TickerProviderStateMixin {
  late AnimationController _waveAnimationController;
  late AnimationController _fillFluidController;
  
  int _countdownClock = 5;
  Timer? _countdownTimer;
  bool _isDelaySequenceComplete = false;
  final TextEditingController _pinResetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();

    _fillFluidController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    if (!widget.profile.hasExceededLimit) {
      _fillFluidController.forward();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) return;
        setState(() {
          if (_countdownClock > 1) {
            _countdownClock--;
          } else {
            _isDelaySequenceComplete = true;
            _countdownTimer?.cancel();
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _waveAnimationController.dispose();
    _fillFluidController.dispose();
    _countdownTimer?.cancel();
    _pinResetController.dispose();
    super.dispose();
  }

  void _processSecureReset() {
    if (_pinResetController.text == widget.profile.accessPinCode) {
      widget.onOverrideUnlocked();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Allocation Limits Restructured Successfully'), backgroundColor: Colors.amber),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect Enforced Pin'), backgroundColor: Colors.redAccent),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hardLocked = widget.profile.hasExceededLimit;

    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder( // FIXED: Guarantees explicit width context boundaries to prevent layout fracturing
        builder: (context, constraints) {
          return Stack(
            children: [
              // Custom Fluid Liquid Simulator Painter Structure
              AnimatedBuilder(
                animation: Listenable.merge([_waveAnimationController, _fillFluidController]),
                builder: (context, child) {
                  return SizedBox(
                    width: constraints.maxWidth,
                    height: constraints.maxHeight,
                    child: CustomPaint(
                      size: Size(constraints.maxWidth, constraints.maxHeight),
                      painter: FluidWavePainter(
                        waveWaveformValue: _waveAnimationController.value,
                        fluidVolumeFillLevel: hardLocked ? 1.0 : _fillFluidController.value,
                        liquidColor: hardLocked 
                            ? Colors.redAccent.withOpacity(0.15) 
                            : Colors.cyanAccent.withOpacity(0.12),
                      ),
                    ),
                  );
                },
              ),

              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // App Ident structural frame
                      Column(
                        children: [
                          const SizedBox(height: 40),
                          Icon(widget.profile.visualIcon, size: 48, color: hardLocked ? Colors.redAccent : Colors.cyanAccent),
                          const SizedBox(height: 16),
                          Text(
                            widget.profile.readableName,
                            style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w300),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            hardLocked ? 'DAILY LIMIT REACHED' : 'INTENTIONAL INTERVENTION',
                            style: TextStyle(
                              color: hardLocked ? Colors.redAccent : Colors.white30, 
                              fontSize: 11, 
                              letterSpacing: 1.5, 
                              fontWeight: FontWeight.w600
                            ),
                          ),
                        ],
                      ),

                      // Core interaction hub logic blocks
                      Column(
                        children: [
                          if (hardLocked) ...[
                            const Text(
                              'You have exhausted your set usage allocation frame for this application.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white60, fontSize: 14, height: 1.5),
                            ),
                            const SizedBox(height: 32),
                            
                            if (widget.profile.IsSecurityEnforced) ...[
                              TextField(
                                controller: _pinResetController,
                                keyboardType: TextInputType.number,
                                obscureText: true,
                                maxLength: 4,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.white, fontFamily: 'JetBrains Mono', letterSpacing: 8),
                                decoration: const InputDecoration(
                                  hintText: 'PIN TO UNLOCK',
                                  hintStyle: TextStyle(color: Colors.white24, letterSpacing: 1, fontSize: 12),
                                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
                                ),
                                onChanged: (val) {
                                  if (val.length == 4) _processSecureReset();
                                },
                              ),
                              const SizedBox(height: 16),
                            ],

                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.redAccent),
                                minimumSize: const Size(double.infinity, 50),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Return to Home Screen', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                            ),
                          ] else ...[
                            // Dynamic 5s wait block layout
                            if (!_isDelaySequenceComplete) ...[
                              Text(
                                '$_countdownClock',
                                style: const TextStyle(fontFamily: 'JetBrains Mono', color: Colors.white, fontSize: 48, fontWeight: FontWeight.w200),
                              ),
                              const SizedBox(height: 12),
                              const Text('Acknowledge your decision path...', style: TextStyle(color: Colors.white24, fontSize: 13)),
                            ] else ...[
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.cyanAccent,
                                  minimumSize: const Size(double.infinity, 52),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                onPressed: () async {
                                  // Clear the route layout first
                                  if (context.mounted) Navigator.pop(context);
                                  
                                  widget.onOverrideUnlocked();

                                  // Fire layout target app launch task
                                  await LauncherService.launchApp(
                                    widget.profile.packageId,
                                  );
                                },
                                child: const Text('Open Intentionally', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600)),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Changed my Mind', style: TextStyle(color: Colors.white38)),
                              )
                            ]
                          ],
                          const SizedBox(height: 40),
                        ],
                      )
                    ],
                  ),
                ),
              )
            ],
          );
        },
      ),
    );
  }
}

class FluidWavePainter extends CustomPainter {
  final double waveWaveformValue;
  final double fluidVolumeFillLevel;
  final Color liquidColor;

  FluidWavePainter({required this.waveWaveformValue, required this.fluidVolumeFillLevel, required this.liquidColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Safety guard to halt paint calculation if sizing dimensions fail initialization
    if (size.width == 0 || size.height == 0) return;

    final paint = Paint()..color = liquidColor;
    final path = Path();

    double targetHeight = size.height * (1.0 - fluidVolumeFillLevel);

    path.moveTo(0, targetHeight);
    
    // Explicit interpolation bounds stepping logic
    for (double x = 0; x <= size.width; x++) {
      double waveSine = sin((x / size.width * 2 * pi) + (waveWaveformValue * 2 * pi));
      double y = targetHeight + (waveSine * 12); 
      path.lineTo(x, y);
    }

    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant FluidWavePainter oldDelegate) {
    return oldDelegate.waveWaveformValue != waveWaveformValue || 
           oldDelegate.fluidVolumeFillLevel != fluidVolumeFillLevel;
  }
}