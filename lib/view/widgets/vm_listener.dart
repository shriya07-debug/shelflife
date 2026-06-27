import 'package:flutter/material.dart';

/// Convenience wrapper around ListenableBuilder for multiple VMs.
class VMListener extends StatelessWidget {
  final Listenable listenable;
  final Widget Function(BuildContext) builder;
  const VMListener({
    super.key,
    required this.listenable,
    required this.builder,
  });
  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: listenable,
      builder: (ctx, _) => builder(ctx),
    );
  }
}

/// Multi-listenable convenience.
Listenable mergeListenables(List<Listenable> list) => Listenable.merge(list);
