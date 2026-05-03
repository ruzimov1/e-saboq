import 'package:flutter/material.dart';

import '../../../../core/widgets/app_bar_back_or_home.dart';
import '../../../../core/widgets/app_profile_icon.dart';
import '../../../../router/method_route_args.dart';

class PollMethodScreen extends StatelessWidget {
  const PollMethodScreen({super.key, this.args});

  final MethodRouteArgs? args;

  @override
  Widget build(BuildContext context) {
    final id = args?.methodId ?? '—';
    return Scaffold(
      appBar: AppBar(
        leadingWidth: AppBarBackOrHomeLeading.leadingWidth(context),
        leading: const AppBarBackOrHomeLeading(),
        title: const Text('So\'rovnoma'),
        actions: const [AppProfileIcon()],
      ),
      body: Center(
        child: Text('Poll · metodId: $id', textAlign: TextAlign.center),
      ),
    );
  }
}
