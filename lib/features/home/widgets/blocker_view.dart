import 'package:aura/features/blocker/data/blocker_profile.dart';
import 'package:aura/features/blocker/data/blocker_service.dart';
import 'package:aura/features/blocker/presentation/views/fluid_friction_overlay.dart';
import 'package:flutter/material.dart';

class BlockerView extends StatefulWidget {
  const BlockerView({super.key});

  @override
  State<BlockerView> createState() => _BlockerViewState();
}

class _BlockerViewState extends State<BlockerView> {
  String _searchQuery = "";
  late Future<void> _initFuture;

  @override
  void initState() {
    super.initState();
    // Ensures apps are only fetched once per app session
    _initFuture = BlockerService.instance.fetchInstalledApps();
  }

  void _triggerPasscodeAssignment(BlockerProfile profile) {
    final TextEditingController pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121214),
        title: Text(
          'Lock ${profile.readableName} Configurations',
          style: const TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          style: const TextStyle(color: Colors.white, fontFamily: 'JetBrains Mono'),
          decoration: const InputDecoration(
            hintText: 'Enter 4-Digit Pin',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () async {
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
            child: const Text('Enforce', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
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
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF121214),
        title: const Text(
          'Enter Passcode to Modify',
          style: TextStyle(color: Colors.white, fontSize: 15),
        ),
        content: TextField(
          controller: pinController,
          keyboardType: TextInputType.number,
          obscureText: true,
          maxLength: 4,
          style: const TextStyle(color: Colors.white, fontFamily: 'JetBrains Mono'),
          decoration: const InputDecoration(
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
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
            child: const Text('Verify', style: TextStyle(color: Colors.cyanAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.cyanAccent),
          );
        }

        // Apply search filter to the persisted list
        final filteredProfiles = BlockerService.instance.profiles
            .where((p) => p.readableName.toLowerCase().contains(_searchQuery.toLowerCase()))
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

              // Search Bar
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                style: const TextStyle(color: Colors.white, fontFamily: 'JetBrains Mono'),
                decoration: InputDecoration(
                  hintText: 'Search apps...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: const Icon(Icons.search, color: Colors.white38, size: 20),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.03),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.05)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(15),
                    borderSide: BorderSide(color: Colors.cyanAccent.withOpacity(0.5)),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Master Focus Core Switch
              _buildGlassBlock(
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
                    style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                  ),
                  value: BlockerService.instance.isMasterFocusModeActive,
                  activeColor: Colors.cyanAccent,
                  onChanged: (val) async {
                    await BlockerService.instance.setMasterFocusMode(val);
                    setState(() {});
                  },
                ),
              ),
              const SizedBox(height: 28),

              // Section Header
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 12),
                child: Text(
                  'Spectrum Restrictions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),

              // App Profiles List
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Column(
                  children: filteredProfiles.map((profile) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildGlassBlock(
                        child: ExpansionTile(
                          iconColor: Colors.white38,
                          collapsedIconColor: Colors.white24,
                          leading: Icon(
                            profile.visualIcon,
                            color: profile.isRestricted ? Colors.cyanAccent : Colors.white38,
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
                            'Limit: ${profile.allocationLimitMinutes}m | Logged: ${profile.currentAccumulatedMinutes}m',
                            style: TextStyle(
                              color: profile.hasExceededLimit ? Colors.redAccent : Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              profile.IsSecurityEnforced
                                  ? Icons.lock_rounded
                                  : Icons.lock_open_rounded,
                              color: profile.IsSecurityEnforced
                                  ? Colors.amberAccent
                                  : Colors.white24,
                              size: 18,
                            ),
                            onPressed: () => profile.IsSecurityEnforced
                                ? _verifyUnlockSequence(profile, () async {
                                    profile.IsSecurityEnforced = false;
                                    profile.accessPinCode = null;
                                    await BlockerService.instance.updateProfile(profile);
                                    setState(() {});
                                  })
                                : _triggerPasscodeAssignment(profile),
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Restrict Switch
                                  Row(
                                    children: [
                                      const Text(
                                        'Restrict',
                                        style: TextStyle(color: Colors.white60, fontSize: 12),
                                      ),
                                      const SizedBox(width: 4),
                                      Switch(
                                        value: profile.isRestricted,
                                        activeColor: Colors.cyanAccent,
                                        onChanged: (val) => _verifyUnlockSequence(
                                          profile,
                                          () async {
                                            profile.isRestricted = val;
                                            await BlockerService.instance.updateProfile(profile);
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ],
                                  ),

                                  // Time Limit Dropdown
                                  DropdownButton<int>(
                                    dropdownColor: const Color(0xFF121214),
                                    underline: const SizedBox(),
                                    value: profile.allocationLimitMinutes,
                                    style: const TextStyle(
                                      color: Colors.cyanAccent,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    items: [15, 30, 45, 60]
                                        .map((int value) => DropdownMenuItem(
                                              value: value,
                                              child: Text('${value}m'),
                                            ))
                                        .toList(),
                                    onChanged: (newLimit) => newLimit != null
                                        ? _verifyUnlockSequence(
                                            profile,
                                            () async {
                                              profile.allocationLimitMinutes = newLimit;
                                              await BlockerService.instance.updateProfile(profile);
                                              setState(() {});
                                            },
                                          )
                                        : null,
                                  ),

                                  // Simulate Button
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withOpacity(0.05),
                                      elevation: 0,
                                    ),
                                    onPressed: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FluidFrictionOverlay(
                                          profile: profile,
                                          onOverrideUnlocked: () async {
                                            profile.currentAccumulatedMinutes = 0;
                                            await BlockerService.instance.updateProfile(profile);
                                            setState(() {});
                                          },
                                        ),
                                      ),
                                    ),
                                    child: const Text(
                                      'Simulate',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildGlassBlock({required Widget child}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.02),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: child,
    );
  }
}