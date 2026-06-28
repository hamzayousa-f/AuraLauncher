import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/blocker_profile.dart';
import '../../../../core/services/launcher_service.dart';

class FluidFrictionOverlay extends StatefulWidget {
  final BlockerProfile profile;
  final VoidCallback onOverrideUnlocked;

  const FluidFrictionOverlay({
    super.key, 
    required this.profile, 
    required this.onOverrideUnlocked
  });

  @override
  State<FluidFrictionOverlay> createState() => _FluidFrictionOverlayState();
}

class _FluidFrictionOverlayState extends State<FluidFrictionOverlay> with TickerProviderStateMixin {
  late AnimationController _waveAnimationController;
  late AnimationController _fillFluidController;
  
  static const _channel = MethodChannel('com.hamza.wellbeing.aura/launcher');
  
  int _countdownClock = 5;
  Timer? _countdownTimer;
  bool _isDelaySequenceComplete = false;
  final TextEditingController _pinResetController = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    _waveAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
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
        const SnackBar(
          content: Text('Allocation Limits Restructured'), 
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect Enforced Pin'), backgroundColor: Colors.redAccent),
      );
      _pinResetController.clear();
    }
  }

  Future<void> _applyNativeBypass() async {
    try {
      await _channel.invokeMethod('tempBypassApp', {
        'packageName': widget.profile.packageId,
      });
    } catch (e) {
      debugPrint("Native Bypass Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hardLocked = widget.profile.hasExceededLimit;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          // THE FLUID BACKGROUND (Optimized with RepaintBoundary)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([_waveAnimationController, _fillFluidController]),
                builder: (context, child) {
                  return CustomPaint(
                    painter: FluidWavePainter(
                      waveWaveformValue: _waveAnimationController.value,
                      fluidVolumeFillLevel: hardLocked ? 1.0 : _fillFluidController.value,
                      liquidColor: hardLocked 
                          ? Colors.redAccent.withOpacity(0.18) 
                          : Colors.cyanAccent.withOpacity(0.12),
                    ),
                  );
                },
              ),
            ),
          ),

          // UI OVERLAY
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  
                  // Top Section: Label and Icon (Now Center Aligned)
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(
                            widget.profile.visualIcon, 
                            size: 42, 
                            color: hardLocked ? Colors.redAccent : Colors.cyanAccent
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.profile.readableName.toUpperCase(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white, 
                            fontSize: 22, 
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          hardLocked ? 'DAILY LIMIT EXHAUSTED' : 'INTENTIONAL INTERVENTION',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: hardLocked ? Colors.redAccent : Colors.white24, 
                            fontSize: 10, 
                            letterSpacing: 2, 
                            fontWeight: FontWeight.w700
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // Bottom Section: Interaction (Center Aligned)
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      children: [
                        if (hardLocked) ...[
                          const Text(
                            'You have reached your allocated time.\nReflection is required before reset.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white54, fontSize: 13, height: 1.6),
                          ),
                          const SizedBox(height: 40),
                          
                          if (widget.profile.IsSecurityEnforced) ...[
                            _buildPinField(),
                            const SizedBox(height: 24),
                          ],

                          _buildActionButton(
                            label: 'Return to Hub',
                            onPressed: () => Navigator.pop(context),
                            isPrimary: false,
                            color: Colors.redAccent,
                          ),
                        ] else ...[
                          if (!_isDelaySequenceComplete) ...[
                            Text(
                              '0$_countdownClock',
                              style: const TextStyle(
                                fontFamily: 'JetBrains Mono', 
                                color: Colors.white, 
                                fontSize: 56, 
                                fontWeight: FontWeight.w100
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Acknowledge your decision path', 
                              style: TextStyle(color: Colors.white24, fontSize: 12, letterSpacing: 0.5)
                            ),
                          ] else ...[
                            _buildActionButton(
                              label: 'Continue to App',
                              onPressed: () async {
                                await _applyNativeBypass();
                                if (context.mounted) Navigator.pop(context);
                                widget.onOverrideUnlocked();
                                await LauncherService.launchApp(widget.profile.packageId);
                              },
                              isPrimary: true,
                              color: Colors.cyanAccent,
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Changed my mind', 
                                style: TextStyle(color: Colors.white38, fontSize: 13)
                              ),
                            )
                          ]
                        ],
                        const SizedBox(height: 40),
                      ],
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPinField() {
    return Container(
      width: 200,
      child: TextField(
        controller: _pinResetController,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 4,
        textAlign: TextAlign.center,
        cursorColor: Colors.redAccent,
        style: const TextStyle(
          color: Colors.white, 
          fontSize: 24,
          fontFamily: 'JetBrains Mono', 
          letterSpacing: 12
        ),
        decoration: const InputDecoration(
          counterText: "",
          hintText: 'PIN',
          hintStyle: TextStyle(color: Colors.white12, letterSpacing: 2, fontSize: 14),
          enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white12)),
          focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.redAccent)),
        ),
        onChanged: (val) {
          if (val.length == 4) _processSecureReset();
        },
      ),
    );
  }

  Widget _buildActionButton({
    required String label, 
    required VoidCallback onPressed, 
    required bool isPrimary,
    required Color color,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isPrimary ? color : Colors.transparent,
        foregroundColor: isPrimary ? Colors.black : color,
        elevation: 0,
        side: isPrimary ? BorderSide.none : BorderSide(color: color.withOpacity(0.5)),
        minimumSize: const Size(double.infinity, 56),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      onPressed: onPressed,
      child: Text(
        label, 
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, letterSpacing: 0.5)
      ),
    );
  }
}

class FluidWavePainter extends CustomPainter {
  final double waveWaveformValue;
  final double fluidVolumeFillLevel;
  final Color liquidColor;

  FluidWavePainter({
    required this.waveWaveformValue, 
    required this.fluidVolumeFillLevel, 
    required this.liquidColor
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width == 0 || size.height == 0) return;

    final paint = Paint()
      ..color = liquidColor
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = Path();
    double targetHeight = size.height * (1.0 - fluidVolumeFillLevel);
    
    // Wave smoothing logic: Higher amplitude in center, flatter at edges
    double dynamicAmplitude = 15 * sin(fluidVolumeFillLevel * pi);

    path.moveTo(0, targetHeight);
    
    // OPTIMIZATION: Increment by 4 instead of 1 to reduce vertex calculation
    for (double x = 0; x <= size.width; x += 4) {
      double waveSine = sin((x / size.width * 2 * pi) + (waveWaveformValue * 2 * pi));
      double y = targetHeight + (waveSine * dynamicAmplitude); 
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