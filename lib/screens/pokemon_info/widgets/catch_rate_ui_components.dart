import 'package:flutter/material.dart';
import '../../../l10n/app_translations.dart';
import '../../../utils/catch_rate/models.dart';
import '../../../utils/catch_rate/strategy_base.dart';
import '../../../utils/notification_helper.dart';

class CatchRateResultCard extends StatelessWidget {
  final CatchRateResult result;
  final CatchRateStrategy strategy;

  const CatchRateResultCard({
    super.key,
    required this.result,
    required this.strategy,
  });

  @override
  Widget build(BuildContext context) {
    try {
      bool isGuaranteed = result.catchChance >= 100.0;
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isGuaranteed
              ? Colors.green.withValues(alpha: 0.2)
              : Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isGuaranteed
                ? Colors.green
                : Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            if (result.glitchText != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.bug_report, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      result.glitchText!,
                      style: const TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              Translator.get('catch_chance'),
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              isGuaranteed
                  ? Translator.get('guaranteed_catch')
                  : '~ ${result.catchChance.toStringAsFixed(1)} %',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: isGuaranteed
                    ? Colors.green
                    : Theme.of(context).colorScheme.primary,
              ),
            ),
            if (strategy.showCritSettings &&
                result.critChance > 0 &&
                !isGuaranteed) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                Translator.get('critical_catch_chance'),
                style: const TextStyle(fontSize: 12),
              ),
              Text(
                '~ ${result.critChance.toStringAsFixed(2)} %',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      );
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationHelper.showError(
          "${Translator.get('error_calc_ui_result')} $e",
        );
      });
      return const SizedBox.shrink();
    }
  }
}

class CatchRateHpStatusWidget extends StatelessWidget {
  final int statusType;
  final double hpPercent;
  final ValueChanged<int> onStatusChanged;
  final ValueChanged<double> onHpChanged;

  const CatchRateHpStatusWidget({
    super.key,
    required this.statusType,
    required this.hpPercent,
    required this.onStatusChanged,
    required this.onHpChanged,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<int>(
            initialValue: statusType,
            decoration: InputDecoration(
              labelText: Translator.get('status_condition'),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              filled: true,
              fillColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            ),
            items: [
              DropdownMenuItem(
                value: 0,
                child: Text(Translator.get('status_none')),
              ),
              DropdownMenuItem(
                value: 1,
                child: Text(Translator.get('status_par_psn_brn')),
              ),
              DropdownMenuItem(
                value: 2,
                child: Text(Translator.get('status_slp_frz')),
              ),
            ],
            onChanged: (val) {
              if (val != null) onStatusChanged(val);
            },
          ),
          const SizedBox(height: 16),
          Text('${Translator.get('hp_percent')}: ${hpPercent.toInt()}%'),
          Slider(
            value: hpPercent,
            min: 1.0,
            max: 100.0,
            divisions: 99,
            activeColor: hpPercent > 50
                ? Colors.green
                : (hpPercent > 20 ? Colors.orange : Colors.red),
            label: '${hpPercent.toInt()}%',
            onChanged: onHpChanged,
          ),
        ],
      );
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationHelper.showError(
          "${Translator.get('error_calc_ui_hp')} $e",
        );
      });
      return const SizedBox.shrink();
    }
  }
}

class CatchRateCritSettingsWidget extends StatelessWidget {
  final double dexMultiplier;
  final bool hasCatchingCharm;
  final double selectedGen;
  final Map<double, String> dexMultipliers;
  final ValueChanged<double> onDexMultiplierChanged;
  final ValueChanged<bool> onCatchingCharmChanged;

  const CatchRateCritSettingsWidget({
    super.key,
    required this.dexMultiplier,
    required this.hasCatchingCharm,
    required this.selectedGen,
    required this.dexMultipliers,
    required this.onDexMultiplierChanged,
    required this.onCatchingCharmChanged,
  });

  @override
  Widget build(BuildContext context) {
    try {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(12),
        ),
        color: Theme.of(context).colorScheme.surface,
        child: ExpansionTile(
          leading: const Icon(Icons.star_border),
          title: Text(
            Translator.get('calc_crit_settings'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DropdownButtonFormField<double>(
                    initialValue: dexMultiplier,
                    decoration: InputDecoration(
                      labelText: Translator.get('dex_caught'),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      prefixIcon: const Icon(Icons.menu_book),
                    ),
                    items: dexMultipliers.entries.map((entry) {
                      return DropdownMenuItem<double>(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          style: const TextStyle(fontSize: 13),
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) onDexMultiplierChanged(val);
                    },
                  ),
                  if (selectedGen >= 8.0) ...[
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(Translator.get('catching_charm')),
                      secondary: const Icon(Icons.key),
                      value: hasCatchingCharm,
                      onChanged: onCatchingCharmChanged,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    } catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        NotificationHelper.showError(
          "${Translator.get('error_calc_ui_crit')} $e",
        );
      });
      return const SizedBox.shrink();
    }
  }
}
