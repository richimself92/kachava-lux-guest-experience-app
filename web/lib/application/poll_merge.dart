import '../domain/entities/experience_entities.dart';

/// Pure rules for applying a server snapshot on top of the guest's local
/// state, so a background poll never discards what the guest is doing.
abstract final class PollMerge {
  /// Server larder items with quantities reset, except those found in
  /// [unsavedCart] (the guest's edits not yet sent to the server).
  static List<LarderItem> larder(
    List<LarderItem> incoming, {
    List<LarderItem> unsavedCart = const [],
  }) {
    final kept = {for (final i in unsavedCart) i.id: i.quantity};
    return [
      for (final item in incoming)
        item.copyWith(quantity: kept[item.id] ?? 0, isConfirmed: false),
    ];
  }

  /// A background poll never unlocks a request the guest already made.
  static List<ExperienceItem> experiences(
    List<ExperienceItem> incoming,
    List<ExperienceItem> previous,
  ) {
    final prevById = {for (final e in previous) e.id: e};
    return [
      for (final exp in incoming)
        switch (prevById[exp.id]) {
          final prev? when !exp.isReserved && prev.isReserved => prev,
          _ => exp,
        },
    ];
  }
}
