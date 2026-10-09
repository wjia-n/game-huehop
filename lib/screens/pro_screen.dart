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
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      widget.audio.win();
      toySnack(context, 'PRO unlocked — enjoy everything! 🎉', _t);
      widget.store.proPurchased.value = false;
    }
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
    widget.store.proPurchased.removeListener(_onPro);
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
                  _ComparisonCard(theme: t, isPro: s.isPro),
                  const SizedBox(height: 16),
                  _BuyCard(
                    theme: t,
                    settings: s,
                    store: widget.store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 16),
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
class _ComparisonCard extends StatelessWidget {
  final HueHopThemeDef theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    const rows = [
      ('Endless + Score Attack modes', true, true),
      ('Chill & Zippy difficulties', true, true),
      ('🔥 Wild difficulty (5 colors, drifting gates)', false, true),
      ('9 playful themes', true, true),
      ('5 extra PRO themes', false, true),
      ('6 ball styles', true, true),
      ('4 extra PRO ball styles', false, true),
      ('6 gate styles', true, true),
      ('2 extra PRO gate styles', false, true),
      ('🎨 Custom color creator', false, true),
    ];
    return ToyUi.panel(
      theme: t,
      child: Column(
        children: [
          Row(
            children: [
              const Spacer(),
              SizedBox(
                  width: 64,
                  child: Text('FREE',
                      textAlign: TextAlign.center,
                      style: ToyUi.label(12, theme: t))),
              SizedBox(
                  width: 64,
                  child: Text('PRO',
                      textAlign: TextAlign.center,
                      style: ToyUi.label(12, theme: t, color: t.accent))),
            ],
          ),
          const Divider(height: 18),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                      child: Text(r.$1, style: ToyUi.body(14, theme: t))),
                  SizedBox(
                    width: 64,
                    child: Text(r.$2 ? '✅' : '—',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16)),
                  ),
                  SizedBox(
                    width: 64,
                    child: Text(r.$3 ? '✅' : '—',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16)),
                  ),
                ],
              ),
            ),
          if (isPro)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: t.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text('⭐ You are PRO — everything is unlocked!',
                    style: ToyUi.title(14, theme: t, color: t.accent)),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _BuyCard extends StatelessWidget {
  final HueHopThemeDef theme;
  final HueHopSettings settings;
  final StoreService store;
  final HueHopAudio audio;
  const _BuyCard(
      {required this.theme,
      required this.settings,
      required this.store,
      required this.audio});

  @override
  Widget build(BuildContext context) {
    final t = theme;
    // Rebuild when the store finishes init: storeReady/error are plain
    // fields, and store.refresh fires exactly once per state change.
    return ValueListenableBuilder<int>(
      valueListenable: store.refresh,
      builder: (_, _, _) => ToyUi.panel(
        theme: t,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UNLOCK PRO', style: ToyUi.label(13, theme: t)),
            const SizedBox(height: 8),
            ValueListenableBuilder<bool>(
              valueListenable: store.purchaseInProgress,
              builder: (_, busy, _) => ValueListenableBuilder<String?>(
                valueListenable: store.purchaseError,
                builder: (_, err, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!store.storeReady)
                      Text(
                        store.error ?? 'Store is warming up…',
                        style: ToyUi.body(14, theme: t),
                      ),
                    if (store.storeReady && store.proProduct != null)
                      _productRow(context, store.proProduct!, () {
                        audio.click();
                        store.buyPro();
                      }, busy),
                    if (err != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(err,
                            style: ToyUi.body(13, theme: t,
                                color: Colors.red)),
                      ),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        audio.click();
                        store.restore();
                        toySnack(context, 'Checking past purchases…', t);
                      },
                      child: Text('Restore purchases',
                          style: ToyUi.body(14, theme: t, color: t.accent)
                              .copyWith(
                                  decoration: TextDecoration.underline)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productRow(BuildContext context, ProductDetails p,
      VoidCallback onBuy, bool busy) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hue Hop PRO', style: ToyUi.title(17, theme: theme)),
              Text('One-time unlock, yours forever.',
                  style: ToyUi.body(13, theme: theme)),
              Text(p.price,
                  style: ToyUi.title(18,
                      theme: theme, color: theme.accent)),
            ],
          ),
        ),
        ToyUi.button(
          theme: theme,
          text: busy ? '…' : 'Buy',
          fontSize: 16,
          padding:
              const EdgeInsets.symmetric(horizontal: 26, vertical: 12),
          onTap: busy ? () {} : onBuy,
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
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
