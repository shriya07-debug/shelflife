/// Unit handling — groups and conversion logic.
enum UnitGroup { mass, volume, count }

class AppUnit {
  final String code;     // 'g', 'kg', 'oz', 'lb', 'ml', 'l', 'tsp', etc.
  final String label;    // user-facing label
  final UnitGroup group;
  /// Factor to convert FROM this unit TO the base unit of its group.
  /// Mass base = gram. Volume base = milliliter. Count base = unit.
  final double toBase;

  const AppUnit(this.code, this.label, this.group, this.toBase);
}

class AppUnits {
  AppUnits._();

  // ---- Mass (base = gram) ------------------------------------------------
  static const g  = AppUnit('g',  'g',  UnitGroup.mass, 1.0);
  static const kg = AppUnit('kg', 'kg', UnitGroup.mass, 1000.0);
  static const oz = AppUnit('oz', 'oz', UnitGroup.mass, 28.3495);
  static const lb = AppUnit('lb', 'lb', UnitGroup.mass, 453.592);

  // ---- Volume (base = milliliter) ----------------------------------------
  static const ml    = AppUnit('ml',   'ml',  UnitGroup.volume, 1.0);
  static const l     = AppUnit('l',    'L',   UnitGroup.volume, 1000.0);
  static const tsp   = AppUnit('tsp',  'tsp', UnitGroup.volume, 4.92892);
  static const tbsp  = AppUnit('tbsp', 'tbsp',UnitGroup.volume, 14.7868);
  static const cup   = AppUnit('cup',  'cup', UnitGroup.volume, 236.588);
  static const flOz  = AppUnit('fl_oz','fl oz',UnitGroup.volume,29.5735);

  // ---- Count (base = unit) -----------------------------------------------
  static const unit  = AppUnit('unit',  'unit',  UnitGroup.count, 1.0);
  static const piece = AppUnit('piece', 'piece', UnitGroup.count, 1.0);
  static const pack  = AppUnit('pack',  'pack',  UnitGroup.count, 1.0);
  static const bag   = AppUnit('bag',   'bag',   UnitGroup.count, 1.0);

  static const all = <AppUnit>[
    unit, piece, pack, bag,
    g, kg, oz, lb,
    ml, l, tsp, tbsp, cup, flOz,
  ];

  static AppUnit byCode(String code) {
    for (final u in all) {
      if (u.code == code) return u;
    }
    return unit;
  }

  /// Best secondary display unit (for "≈" hint).
  /// e.g. 500 g  → "≈ 1.10 lb"
  ///      1.5 lb → "≈ 680 g"
  static String? secondaryDisplay(double qty, AppUnit unit) {
    if (qty <= 0) return null;
    switch (unit.group) {
      case UnitGroup.mass:
        final inGrams = qty * unit.toBase;
        if (unit.code == 'g' || unit.code == 'kg') {
          // show lb
          final lbVal = inGrams / AppUnits.lb.toBase;
          return '≈ ${_fmt(lbVal)} lb';
        } else {
          // show g (or kg if big)
          if (inGrams >= 1000) return '≈ ${_fmt(inGrams / 1000)} kg';
          return '≈ ${_fmt(inGrams)} g';
        }
      case UnitGroup.volume:
        final inMl = qty * unit.toBase;
        if (unit.code == 'ml' || unit.code == 'l') {
          // show fl oz
          return '≈ ${_fmt(inMl / AppUnits.flOz.toBase)} fl oz';
        } else {
          if (inMl >= 1000) return '≈ ${_fmt(inMl / 1000)} L';
          return '≈ ${_fmt(inMl)} ml';
        }
      case UnitGroup.count:
        return null;
    }
  }

  static String _fmt(double v) {
    if (v >= 100) return v.toStringAsFixed(0);
    if (v >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(2);
  }
}
