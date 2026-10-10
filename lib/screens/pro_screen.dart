import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/huehop_themes.dart';
import '../theme/toy_ui.dart';

/// Hue Hop PRO: Free-vs-Pro comparison, real purchase, restore, and tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
class ProScreen extends StatefulWidget {
  final HueHopAudio audio;
  final HueHopSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  HueHopThemeDef get _t => widget.settings.theme;

  @override
  void initState() {
    super.initState();
    widget.store.init();
    widget.store.lastThanks.addListener(_onThanks);
  }

  
  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    toySnack(context, msg, _t);
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.lastThanks.removeListener(_onThanks);
    widget.store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    return ToyUi.backdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: t.text),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Hue Hop PRO', style: ToyUi.title(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                                    _TipsCard(
                    theme: t,
                    store: widget.store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Free vs Pro comparison table — buyers see the big difference.
class _TipsCard extends StatelessWidget {
  final HueHopThemeDef theme;
  final StoreService store;
  final HueHopAudio audio;
  const _TipsCard(
      {required this.theme, required this.store, required this.audio});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    return ValueListenableBuilder<int>(
      valueListenable: store.refresh,
      builder: (_, _, _) => ToyUi.panel(
        theme: t,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('💛 TIP JAR', style: ToyUi.label(13, theme: t)),
            const SizedBox(height: 6),
            Text('Made by one indie human. Tips keep the hops coming!',
                style: ToyUi.body(13, theme: t)),
            const SizedBox(height: 10),
            if (!store.storeReady)
              Text(store.error ?? 'Store is warming up…',
                  style: ToyUi.body(14, theme: t)),
            if (store.storeReady) ...[
              if (store.coffeeProduct != null)
                _tipRow(context, store.coffeeProduct!, '☕'),
              const SizedBox(height: 8),
              if (store.chocolateProduct != null)
                _tipRow(context, store.chocolateProduct!, '🍫'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _tipRow(
      BuildContext context, ProductDetails p, String emoji) {
    final t = theme;
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.title, style: ToyUi.title(15, theme: t)),
              Text(p.price,
                  style: ToyUi.body(13, theme: t, color: t.accent)),
            ],
          ),
        ),
        ValueListenableBuilder<bool>(
          valueListenable: store.purchaseInProgress,
          builder: (_, busy, _) => ToyUi.button(
            theme: t,
            text: busy ? '…' : 'Tip',
            fontSize: 15,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            onTap: busy
                ? () {}
                : () {
                    audio.click();
                    store.buyTip(p);
                  },
          ),
        ),
      ],
    );
  }
}
