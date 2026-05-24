import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 创建一个与 Riverpod provider 状态字段双向同步的 [TextEditingController]。
///
/// 用于 ConsumerStatefulWidget.initState：初始化 controller 文本为
/// `selector(ref.read(provider))`，并通过 `ref.listenManual` 在 provider
/// 状态变化时把新值写回 controller（仅当文本不同，避免光标跳动）。
/// listenManual 的订阅由 `ref` 自动回收，调用方仍需在 dispose 里释放
/// 返回的 controller。
///
/// 示例：
/// ```dart
/// _nameCtrl = syncedTextController(
///   ref: ref,
///   provider: _provider(),
///   selector: (s) => s.name,
/// );
/// ```
///
/// [watch] 为 false 时只填充初始值、不订阅后续变化（用于新建态的字段，
/// 例如 transaction_form 里编辑态才同步、新建态用户输入优先）。
TextEditingController syncedTextController<S>({
  required WidgetRef ref,
  required ProviderListenable<S> provider,
  required String Function(S state) selector,
  bool watch = true,
}) {
  final controller = TextEditingController(text: selector(ref.read(provider)));
  if (watch) {
    ref.listenManual<S>(provider, (prev, next) {
      final nextText = selector(next);
      final prevText = prev == null ? null : selector(prev);
      if (prevText != nextText && controller.text != nextText) {
        controller.text = nextText;
      }
    });
  }
  return controller;
}
