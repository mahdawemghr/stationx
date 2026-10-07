import 'package:flutter/material.dart';

import '../../app/app_scope.dart';
import '../../app/nav.dart';
import '../../core/theme/sx_spacing.dart';
import '../../core/theme/sx_theme.dart';
import '../../core/theme/sx_typography.dart';
import '../../core/widgets/widgets.dart';

/// Entry screen (Stitch: landing_page). Local-first: "Continue as Guest" opens
/// the app with demo data; Create Account / Log In open the local-profile forms.
class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SxScaffold(
      padding: const EdgeInsets.fromLTRB(SxSpace.md, SxSpace.sm, SxSpace.md, SxSpace.lg),
      gap: SxSpace.md,
      children: [
        const _Header(),
        const _Hero(),
        const SectionHeader('System modules', trailingText: '3 / 3 active'),
        const _Module(
          icon: Icons.fitness_center,
          title: 'Strength',
          tag: 'Rotation',
          subtitle: 'Log sets, reps & load with a sequential workout rotation.',
        ),
        const _Module(
          icon: Icons.directions_run,
          title: 'Cardio',
          tag: 'Adaptive',
          subtitle: 'Runs, treadmill, bike & more — fields adapt per activity.',
        ),
        const _Module(
          icon: Icons.trending_up,
          title: 'Progress',
          tag: 'PR tracking',
          subtitle: 'Volume, personal records & estimated 1RM.',
        ),
        const SizedBox(height: SxSpace.xs),
        SxButton(
          label: 'Create account',
          icon: Icons.fitness_center,
          onPressed: () => AppNav.register(context),
        ),
        SxButton(
          label: 'Log in',
          icon: Icons.login,
          variant: SxButtonVariant.secondary,
          height: 48,
          onPressed: () => AppNav.login(context),
        ),
        _GuestLink(onTap: () {
          context.app.startDemo();
          AppNav.enterApp(context);
        }),
        const _Footer(),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SafeArea(
      bottom: false,
      child: Row(children: [
        const SxLogo(size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('StationX', maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.headlineMd.copyWith(color: c.textHigh, fontWeight: FontWeight.w700)),
            Text('STRENGTH & CARDIO LOG', maxLines: 1, overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.textBody, fontSize: 10)),
          ]),
        ),
        const SizedBox(width: 8),
        const Flexible(child: StatusPill('Local-first', dot: true)),
      ]),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(SxRadius.lg),
        border: Border.all(color: c.hairline),
        color: c.surface1,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [
        Stack(children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0.8, -0.6),
                  radius: 1.1,
                  colors: [c.primary.withValues(alpha: 0.10), c.canvas],
                ),
              ),
            ),
          ),
          Positioned(
            right: -24,
            top: 8,
            child: Icon(Icons.fitness_center, size: 190, color: c.primary.withValues(alpha: 0.05)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(SxSpace.md, 120, SxSpace.md, SxSpace.md),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.terminal, size: 16, color: c.primary),
                const SizedBox(width: 6),
                Flexible(child: Text('PRECISION PROTOCOL', overflow: TextOverflow.ellipsis, style: SxText.labelCaps.copyWith(color: c.primary, letterSpacing: 1.6))),
              ]),
              const SizedBox(height: 8),
              Text('TRAIN.', style: SxText.displayHero.copyWith(color: c.textHigh)),
              Text('TRACK.', style: SxText.displayHero.copyWith(color: c.textHigh)),
              Text('PROGRESS.', style: SxText.displayHero.copyWith(color: c.primary)),
            ]),
          ),
        ]),
        Container(
          color: c.surface2,
          padding: const EdgeInsets.all(SxSpace.md),
          child: Row(children: [
            Expanded(
              child: Text('Log every set, follow your rotation and let progressive overload do the rest — all on your device.',
                  style: SxText.bodyMd.copyWith(color: c.textBody)),
            ),
            const SizedBox(width: 12),
            Icon(Icons.verified_outlined, color: c.primary, size: 24),
          ]),
        ),
      ]),
    );
  }
}

class _Module extends StatelessWidget {
  const _Module({required this.icon, required this.title, required this.tag, required this.subtitle});
  final IconData icon;
  final String title;
  final String tag;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return SxCard(
      padding: const EdgeInsets.all(12),
      child: Row(children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(color: c.surface2, borderRadius: BorderRadius.circular(SxRadius.md), border: Border.all(color: c.hairline)),
          child: Icon(icon, color: c.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
              Text(title.toUpperCase(), style: SxText.headlineSm.copyWith(color: c.textHigh, fontWeight: FontWeight.w700)),
              StatusPill(tag),
            ]),
            const SizedBox(height: 2),
            Text(subtitle, style: SxText.bodySm.copyWith(color: c.textBody)),
          ]),
        ),
      ]),
    );
  }
}

class _GuestLink extends StatelessWidget {
  const _GuestLink({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Center(
      child: TextButton.icon(
        onPressed: onTap,
        style: TextButton.styleFrom(minimumSize: const Size(48, 48), foregroundColor: c.textBody),
        icon: const Icon(Icons.cloud_off_outlined, size: 20),
        label: Text('Continue as Guest (Offline Mode)', style: SxText.bodyMd.copyWith(color: c.textHigh)),
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  @override
  Widget build(BuildContext context) {
    final c = context.sx;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.storage_outlined, size: 16, color: c.textMuted),
      const SizedBox(width: 8),
      Flexible(
        child: Text('LOCAL-FIRST • WORKS WITHOUT A CONNECTION',
            textAlign: TextAlign.center, style: SxText.labelCaps.copyWith(color: c.textMuted, fontSize: 10)),
      ),
    ]);
  }
}
