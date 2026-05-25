import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../data/database/app_database.dart';
import '../../../data/database/app_database_provider.dart';
import '../../../data/seed/default_name_resolver.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/utils/hex_color.dart';
import '../../../shared/widgets/root_page_scaffold.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_radius.dart';
import '../../../theme/app_spacing.dart';
import '../../../theme/app_typography.dart';

/// 与 categories_page 共用阈值：超过即显示搜索框。
const int _kSearchThreshold = 15;

/// 标签管理页（设置入口）：列出全部标签，超出阈值显示搜索框。
class TagsPage extends ConsumerStatefulWidget {
  const TagsPage({super.key});

  @override
  ConsumerState<TagsPage> createState() => _TagsPageState();
}

/// 持有本地搜索关键词；过滤逻辑只走名称（含 i18n 默认名）。
class _TagsPageState extends ConsumerState<TagsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l = AppL10n.of(context);
    final c = context.appColors;
    final async = ref.watch(allTagsProvider);

    return SubPageScaffold(
      title: l.settingsTags,
      actions: [
        IconButton(
          tooltip: l.tagAdd,
          icon: const Icon(LucideIcons.plus),
          onPressed: () => context.push('/settings/tags/new'),
        ),
      ],
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (rows) {
          if (rows.isEmpty) {
            return Center(
              child: Text(
                l.tagEmpty,
                style: AppTypography.sm.copyWith(color: c.textMuted),
              ),
            );
          }
          final filtered = _filter(context, rows, _query);
          return Column(
            children: [
              if (rows.length > _kSearchThreshold)
                _SearchField(
                  hint: l.tagSearchHint,
                  onChanged: (v) => setState(() => _query = v),
                ),
              Expanded(
                child: ListView.separated(
                  padding:
                      const EdgeInsets.symmetric(vertical: AppSpacing.x2),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1,
                      color: c.border,
                      indent: AppSpacing.x4),
                  itemBuilder: (context, i) => _TagRow(tag: filtered[i]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Tag> _filter(BuildContext context, List<Tag> rows, String q) {
    final l = AppL10n.of(context);
    if (q.trim().isEmpty) return rows;
    final needle = q.trim().toLowerCase();
    return rows.where((r) {
      final name = (resolveDefaultName(l, r.nameKey) ?? r.name).toLowerCase();
      return name.contains(needle);
    }).toList();
  }
}

/// 带搜索图标的圆角输入框，用于标签列表的本地过滤。
class _SearchField extends StatelessWidget {
  const _SearchField({required this.hint, required this.onChanged});
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x4,
        AppSpacing.x3,
        AppSpacing.x4,
        AppSpacing.x2,
      ),
      child: TextField(
        onChanged: onChanged,
        style: AppTypography.sm.copyWith(color: c.textPrimary),
        decoration: InputDecoration(
          isDense: true,
          prefixIcon: Icon(LucideIcons.search, size: 18, color: c.textMuted),
          hintText: hint,
          hintStyle: AppTypography.sm.copyWith(color: c.textMuted),
          filled: true,
          fillColor: c.surface,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x3, vertical: AppSpacing.x3),
          border: OutlineInputBorder(
            borderRadius: AppRadius.brXl,
            borderSide: BorderSide(color: c.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.brXl,
            borderSide: BorderSide(color: c.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.brXl,
            borderSide: BorderSide(color: c.action),
          ),
        ),
      ),
    );
  }
}

/// 单条标签行：色块 + 名称，点击进入编辑。
class _TagRow extends StatelessWidget {
  const _TagRow({required this.tag});
  final Tag tag;

  @override
  Widget build(BuildContext context) {
    final c = context.appColors;
    final label =
        resolveDefaultName(AppL10n.of(context), tag.nameKey) ?? tag.name;
    final color = HexColor.fromHex(tag.color);
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: AppRadius.brFull,
        ),
        child: Icon(LucideIcons.tag, color: Colors.white, size: 18),
      ),
      title: Text(
        label,
        style: AppTypography.sm.copyWith(
          color: c.actionInk,
          fontWeight: AppTypography.weightSemibold,
        ),
      ),
      trailing: Icon(LucideIcons.chevronRight, size: 18, color: c.textMuted),
      onTap: () => context.push('/settings/tags/${tag.id}/edit'),
    );
  }
}
