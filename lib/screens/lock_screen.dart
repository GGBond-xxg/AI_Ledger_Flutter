import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:local_auth/local_auth.dart';

import '../app/app_theme.dart';
import '../core/app_toast.dart';
import '../services/ledger_store.dart';

class AppLockGate extends StatelessWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final store = Get.find<LedgerStore>();
    return Obx(() => store.appLocked ? const LockScreen() : child);
  }
}

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen> with WidgetsBindingObserver {
  final LedgerStore store = Get.find<LedgerStore>();
  final LocalAuthentication _auth = LocalAuthentication();
  String _pin = '';
  bool _authenticating = false;
  bool _autoPrompted = false;
  Worker? _foregroundWorker;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _foregroundWorker = ever<bool>(store.appInForegroundRx, (foreground) {
      if (foreground) {
        _promptBiometricsIfReady();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _promptBiometricsIfReady());
  }

  @override
  void dispose() {
    _foregroundWorker?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _promptBiometricsIfReady());
    }
  }

  void _promptBiometricsIfReady() {
    if (!mounted || _autoPrompted || !store.appInForeground || !store.appLocked || !store.appBiometricsEnabled) {
      return;
    }
    _autoPrompted = true;
    _authenticateDevice();
  }

  @override
  Widget build(BuildContext context) {
    final useBiometrics = store.appBiometricsEnabled;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 82,
                height: 82,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(Icons.lock_rounded, size: 42, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(height: 22),
              Text('appLockedTitle'.tr, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
              const SizedBox(height: 8),
              Text(
                useBiometrics ? 'unlockWithBiometricsOrPinDesc'.tr : 'enterPinDesc'.tr,
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textSubtle(context), height: 1.45),
              ),
              const SizedBox(height: 28),
              if (useBiometrics) ...[
                _buildDeviceLock(context),
                const SizedBox(height: 18),
                Text('usePinFallback'.tr, style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
              ],
              _buildPinLock(context),
              const Spacer(),
              Text('privacyLockHint'.tr, textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 12.5, height: 1.35)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceLock(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton.icon(
        onPressed: _authenticating ? null : _authenticateDevice,
        icon: _authenticating
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.fingerprint_rounded),
        label: Text('unlockNow'.tr),
      ),
    );
  }

  Widget _buildPinLock(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(6, (index) {
            final filled = index < _pin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              margin: const EdgeInsets.symmetric(horizontal: 6),
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: filled ? Theme.of(context).colorScheme.primary : Colors.transparent,
                border: Border.all(color: filled ? Theme.of(context).colorScheme.primary : Theme.of(context).dividerColor, width: 1.5),
                shape: BoxShape.circle,
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Obx(() => Text(
              'pinAttemptsRemaining'.trParams({'count': store.remainingPinAttempts.toString()}),
              style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 13),
            )),
        const SizedBox(height: 26),
        _PinKeyboard(onDigit: _onDigit, onDelete: _onDelete),
      ],
    );
  }

  Future<void> _authenticateDevice() async {
    if (_authenticating) return;
    setState(() => _authenticating = true);
    try {
      final ok = await _auth.authenticate(
        localizedReason: 'biometricUnlockReason'.tr,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (ok) {
        await store.unlockApp();
      }
    } catch (e) {
      showAppToast('biometricAuthFailedUsePin'.tr, title: 'unlockFailed'.tr, icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) setState(() => _authenticating = false);
    }
  }

  Future<void> _onDigit(String digit) async {
    if (_pin.length >= 6) return;
    setState(() => _pin += digit);
    if (_pin.length == 6) {
      final ok = await store.verifyPinAndUnlock(_pin);
      if (ok) return;
      if (!store.appLockEnabled) {
        showAppToast('dataWipedAfterFailedAttempts'.tr, title: 'dataWiped'.tr, icon: Icons.warning_rounded);
        return;
      }
      setState(() => _pin = '');
      showAppToast('pinIncorrect'.tr, title: 'unlockFailed'.tr, icon: Icons.error_outline_rounded);
    }
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }
}

class _PinKeyboard extends StatelessWidget {
  const _PinKeyboard({required this.onDigit, required this.onDelete});

  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 14,
        childAspectRatio: 1.65,
      ),
      itemBuilder: (context, index) {
        final key = keys[index];
        if (key.isEmpty) return const SizedBox.shrink();
        final isDelete = key == 'del';
        return Material(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(22),
          child: InkWell(
            borderRadius: BorderRadius.circular(22),
            onTap: isDelete ? onDelete : () => onDigit(key),
            child: Center(
              child: isDelete
                  ? const Icon(Icons.backspace_outlined)
                  : Text(key, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            ),
          ),
        );
      },
    );
  }
}
