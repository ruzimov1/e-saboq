import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

/// Tarmoq holati bo'yicha ingichka banner (connectivity_plus).
class NetworkStatusBannerHost extends StatefulWidget {
  const NetworkStatusBannerHost({super.key, required this.child});

  final Widget child;

  @override
  State<NetworkStatusBannerHost> createState() =>
      _NetworkStatusBannerHostState();
}

class _NetworkStatusBannerHostState extends State<NetworkStatusBannerHost> {
  List<ConnectivityResult> _last = [ConnectivityResult.none];
  bool _showOnlineFlash = false;

  @override
  void initState() {
    super.initState();
    Connectivity().checkConnectivity().then((r) {
      if (mounted) setState(() => _last = r);
    });
    Connectivity().onConnectivityChanged.listen((r) {
      if (!mounted) return;
      final wasOffline = !_last.any((e) => e != ConnectivityResult.none);
      final nowOnline = r.any((e) => e != ConnectivityResult.none);
      setState(() {
        _last = r;
        if (wasOffline && nowOnline) {
          _showOnlineFlash = true;
          Future<void>.delayed(const Duration(seconds: 3)).then((_) {
            if (mounted) setState(() => _showOnlineFlash = false);
          });
        }
      });
    });
  }

  bool get _offline => !_last.any((e) => e != ConnectivityResult.none);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_offline)
          Material(
            color: Theme.of(context).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                l10n.networkOffline,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        if (_showOnlineFlash && !_offline)
          Material(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                l10n.networkOnline,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        Expanded(child: widget.child),
      ],
    );
  }
}
