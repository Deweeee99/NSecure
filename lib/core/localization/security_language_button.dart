import 'dart:async';

import 'package:flutter/material.dart';

import 'app_localizations_x.dart';
import 'security_locale_controller.dart';

class SecurityLanguageButton extends StatelessWidget {
  const SecurityLanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = SecurityLocaleScope.of(context);
    final l10n = context.l10n;
    final activeLanguageCode = controller.locale?.languageCode ??
        Localizations.localeOf(context).languageCode;

    return PopupMenuButton<String>(
      key: const Key('securityLanguageButton'),
      tooltip: l10n.language,
      initialValue: activeLanguageCode == 'id' ? 'id' : 'en',
      onSelected: (value) => unawaited(controller.setLanguageCode(value)),
      icon: const Icon(Icons.language_rounded),
      itemBuilder: (context) => [
        CheckedPopupMenuItem<String>(
          value: 'id',
          checked: activeLanguageCode == 'id',
          child: Text(l10n.bahasaIndonesia),
        ),
        CheckedPopupMenuItem<String>(
          value: 'en',
          checked: activeLanguageCode != 'id',
          child: Text(l10n.english),
        ),
      ],
    );
  }
}
