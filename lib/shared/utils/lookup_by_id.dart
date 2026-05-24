import '../../data/database/app_database.dart';

/// 在 `List<Category>` 上按 id 线性查找。
///
/// Stats 卡片需要把 distribution slice 的 categoryId 反查成 Category 对象，
/// 旧实现每处都写一个 `findCat(id)` 闭包，此扩展取代之。
extension CategoryListLookup on List<Category> {
  Category? byId(String id) {
    for (final x in this) {
      if (x.id == id) return x;
    }
    return null;
  }
}

extension TagListLookup on List<Tag> {
  Tag? byId(String id) {
    for (final x in this) {
      if (x.id == id) return x;
    }
    return null;
  }
}

extension SourceListLookup on List<Source> {
  Source? byId(String id) {
    for (final x in this) {
      if (x.id == id) return x;
    }
    return null;
  }
}
