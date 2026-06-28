import 'package:aura/features/blocker/data/blocker_profile.dart';
import 'package:aura/features/blocker/data/blocker_service.dart';
import 'package:aura/features/blocker/presentation/views/fluid_friction_overlay.dart';
import 'package:flutter/material.dart';

// ─── Pre-computed colour constants ────────────────────────────────────────────

const _kWhite02    = Color(0x05FFFFFF);
const _kWhite05    = Color(0x0DFFFFFF);
const _kWhite12    = Color(0x1FFFFFFF);
const _kWhite24    = Color(0x3DFFFFFF);
const _kWhite30    = Color(0x4DFFFFFF);
const _kWhite38    = Color(0x61FFFFFF);
const _kWhite40    = Color(0x66FFFFFF);
const _kWhite60    = Color(0x99FFFFFF);
const _kWhite70    = Color(0xB3FFFFFF);
const _kBg         = Color(0xFF121214);
const _kCyan       = Colors.cyanAccent;
const _kCyan50     = Color(0x80CFFFFF); // cyanAccent ~50%
const _kAmber      = Colors.amberAccent;

// ─── Widget ───────────────────────────────────────────────────────────────────

class BlockerView extends StatefulWidget {
  const BlockerView({super.key});

  @override
  State<BlockerView> createState() => _BlockerViewState();
}

class _BlockerViewState extends State<BlockerView> {
  String _searchQuery = '';
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = BlockerService.instance.fetchInstalledApps();
  }

  // ── Dialogs ────────────────────────────────────────────────────────────────

  void _triggerPasscodeAssignment(BlockerProfile profile) {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _PinDialog(
        title: 'Lock ${profile.readableName} Configurations',
        actionLabel: 'Enforce',
        actionColor: _kCyan,
        controller: pinController,
        onAction: () async {
          if (pinController.text.length == 4) {
            profile.accessPinCode = pinController.text;
            profile.IsSecurityEnforced = true;
            await BlockerService.instance.updateProfile(profile);
            if (mounted) {
              setState(() {});
              Navigator.pop(context);
            }
          }
        },
      ),
    );
  }

  void _verifyUnlockSequence(BlockerProfile profile, VoidCallback onSuccess) {
    if (!profile.IsSecurityEnforced) {
      onSuccess();
      return;
    }
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => _PinDialog(
        title: 'Enter Passcode to Modify',
        actionLabel: 'Verify',
        actionColor: _kCyan,
        controller: pinController,
        onAction: () {
          if (pinController.text == profile.accessPinCode) {
            Navigator.pop(context);
            onSuccess();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Invalid Security Pin'),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: _kCyan),
          );
        }

        final List<BlockerProfile> filteredProfiles = BlockerService
            .instance.profiles
            .where((p) => p.readableName
                .toLowerCase()
                .contains(_searchQuery.toLowerCase()))
            .toList();

        return SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Zenith Shield',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w300,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(height: 20),

              // Search bar
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(
                    color: Colors.white, fontFamily: 'JetBrains Mono'),
                decoration: InputDecoration(
                  hintText: 'Search apps...',
                  hintStyle: const TextStyle(color: _kWhite30),
                  prefixIcon:
                      const Icon(Icons.search, color: _kWhite38, size: 20),
                  filled: true,
                  fillColor: _kWhite02,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _kWhite05),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: const BorderSide(color: _kCyan50),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Master Focus Core — SwitchListTile inside Material to fix ink warning
              _GlassBlock(
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: SwitchListTile(
                    title: const Text(
                      'Master Focus Core',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      BlockerService.instance.isMasterFocusModeActive
                          ? 'Interventions active on restricted list'
                          : 'Interventions offline',
                      style:
                          const TextStyle(color: _kWhite40, fontSize: 12),
                    ),
                    value: BlockerService.instance.isMasterFocusModeActive,
                    activeColor: _kCyan,
                    onChanged: (val) async {
                      await BlockerService.instance.setMasterFocusMode(val);
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(height: 28),

              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Spectrum Restrictions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _kWhite40,
                  ),
                ),
              ),

              // App profile list
              Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: filteredProfiles.map((profile) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _AppProfileTile(
                        profile: profile,
                        onVerify: _verifyUnlockSequence,
                        onPasscode: _triggerPasscodeAssignment,
                        onChanged: () => setState(() {}),
                        context: context,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── App profile tile ─────────────────────────────────────────────────────────
// Extracted so the list doesn't rebuild every tile on every setState,
// and so Material is always the direct parent of ExpansionTile/ListTile.

class _AppProfileTile extends StatelessWidget {
  const _AppProfileTile({
    required this.profile,
    required this.onVerify,
    required this.onPasscode,
    required this.onChanged,
    required this.context,
  });

  final BlockerProfile profile;
  final void Function(BlockerProfile, VoidCallback) onVerify;
  final void Function(BlockerProfile) onPasscode;
  final VoidCallback onChanged;
  // Parent context needed for Navigator.push inside Simulate button
  final BuildContext context;

  @override
  Widget build(BuildContext _) {
    return _GlassBlock(
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: ExpansionTile(
          iconColor: _kWhite38,
          collapsedIconColor: _kWhite24,
          leading: Icon(
            profile.visualIcon,
            color: profile.isRestricted ? _kCyan : _kWhite38,
          ),
          title: Text(
            profile.readableName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w400,
            ),
          ),
          subtitle: Text(
            'Limit: ${profile.allocationLimitMinutes}m | '
            'Logged: ${profile.currentAccumulatedMinutes}m',
            style: TextStyle(
              color: profile.hasExceededLimit
                  ? Colors.redAccent
                  : _kWhite38,
              fontSize: 12,
            ),
          ),
          trailing: IconButton(
            icon: Icon(
              profile.IsSecurityEnforced
                  ? Icons.lock_rounded
                  : Icons.lock_open_rounded,
              color: profile.IsSecurityEnforced ? _kAmber : _kWhite24,
              size: 18,
            ),
            onPressed: () => profile.IsSecurityEnforced
                ? onVerify(profile, () async {
                    profile.IsSecurityEnforced = false;
                    profile.accessPinCode = null;
                    await BlockerService.instance.updateProfile(profile);
                    onChanged();
                  })
                : onPasscode(profile),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Restrict switch
                  Row(
                    children: [
                      const Text('Restrict',
                          style: TextStyle(
                              color: _kWhite60, fontSize: 12)),
                      const SizedBox(width: 4),
                      Switch(
                        value: profile.isRestricted,
                        activeColor: _kCyan,
                        onChanged: (val) => onVerify(profile, () async {
                          profile.isRestricted = val;
                          await BlockerService.instance
                              .updateProfile(profile);
                          onChanged();
                        }),
                      ),
                    ],
                  ),

                  // Time limit dropdown
                  DropdownButton<int>(
                    dropdownColor: _kBg,
                    underline: const SizedBox(),
                    value: profile.allocationLimitMinutes,
                    style: const TextStyle(
                      color: _kCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                    items: [15, 30, 45, 60]
                        .map((v) => DropdownMenuItem(
                            value: v, child: Text('${v}m')))
                        .toList(),
                    onChanged: (newLimit) => newLimit != null
                        ? onVerify(profile, () async {
                            profile.allocationLimitMinutes = newLimit;
                            await BlockerService.instance
                                .updateProfile(profile);
                            onChanged();
                          })
                        : null,
                  ),

                  // Simulate button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kWhite05,
                      elevation: 0,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FluidFrictionOverlay(
                          profile: profile,
                          onOverrideUnlocked: () async {
                            profile.currentAccumulatedMinutes = 0;
                            await BlockerService.instance
                                .updateProfile(profile);
                            onChanged();
                          },
                        ),
                      ),
                    ),
                    child: const Text(
                      'Simulate',
                      style: TextStyle(color: _kWhite70, fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Glass block container ────────────────────────────────────────────────────
// Does NOT wrap children in Material — callers must do that themselves
// so ListTile/ExpansionTile/SwitchListTile ink hits the right layer.

class _GlassBlock extends StatelessWidget {
  const _GlassBlock({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _kWhite02,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kWhite05),
      ),
      child: child,
    );
  }
}

// ─── Reusable PIN dialog ──────────────────────────────────────────────────────
// Extracted to eliminate duplicate dialog code between the two dialog methods.

class _PinDialog extends StatelessWidget {
  const _PinDialog({
    required this.title,
    required this.actionLabel,
    required this.actionColor,
    required this.controller,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final Color actionColor;
  final TextEditingController controller;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: _kBg,
      title: Text(title,
          style: const TextStyle(color: Colors.white, fontSize: 16)),
      content: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        obscureText: true,
        maxLength: 4,
        style: const TextStyle(
            color: Colors.white, fontFamily: 'JetBrains Mono'),
        decoration: const InputDecoration(
          hintText: '4-digit PIN',
          hintStyle: TextStyle(color: _kWhite24),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: _kWhite12),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel',
              style: TextStyle(color: _kWhite38)),
        ),
        TextButton(
          onPressed: onAction,
          child: Text(actionLabel,
              style: TextStyle(color: actionColor)),
        ),
      ],
    );
  }
}