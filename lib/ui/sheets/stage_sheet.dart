import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../domain/models.dart';
import '../app_scope.dart';
import '../type_info.dart';
import '../widgets/common.dart';

/// Lets the user set the stage of a typed item (unread / reading / read ...).
Future<void> showStageSheet(BuildContext context, LaterItem item) {
  final l = context.l10n;
  return showAppSheet<void>(
    context,
    builder: (ctx) => SafeArea(
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(l.itemStage, style: ctx.text.titleLarge),
            ),
          ),
          for (final s in ItemStages.of(item.type))
            ListTile(
              title: Text(TypeInfo.stageLabel(l, item.type, s)),
              trailing: s == item.stage ? Icon(Icons.check_rounded, color: ctx.scheme.primary) : null,
              onTap: () async {
                Navigator.pop(ctx);
                await guarded(context, () => context.appRead.setStage(item.id, s));
              },
            ),
          const SizedBox(height: 12),
        ]),
      ),
    ),
  );
}
