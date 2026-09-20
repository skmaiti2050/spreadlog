/// Regulatory and operational endorsement categories recognized across aviation authorities (SACAA, FAA, EASA).
enum EndorsementCategory {
  general,
  vp, // Variable Pitch Propeller
  ru, // Retractable Undercarriage
  t, // Turbocharged / Supercharged
  p, // Pressurized Cabin
  tw, // Tailwheel
  modelRegister, // Aircraft Model Differences / Rating Register
  nightRating, // Night Flying Rating
  instrumentRating, // Instrument Flying / Navaid Approaches
  other; // Custom / Miscellaneous Regulator Endorsement

  String get displayName {
    switch (this) {
      case EndorsementCategory.general:
        return 'General / Authorizations';
      case EndorsementCategory.vp:
        return 'Variable Pitch Propeller (VP)';
      case EndorsementCategory.ru:
        return 'Retractable Undercarriage (RU)';
      case EndorsementCategory.t:
        return 'Turbocharged (T)';
      case EndorsementCategory.p:
        return 'Pressurized Cabin (P)';
      case EndorsementCategory.tw:
        return 'Tailwheel (TW)';
      case EndorsementCategory.modelRegister:
        return 'Model Differences Register';
      case EndorsementCategory.nightRating:
        return 'Night Rating Endorsement';
      case EndorsementCategory.instrumentRating:
        return 'Instrument Flying / Approaches';
      case EndorsementCategory.other:
        return 'Other Regulator Endorsement';
    }
  }

  String get label => displayName;


  String get code {
    switch (this) {
      case EndorsementCategory.general:
        return 'GENERAL';
      case EndorsementCategory.vp:
        return 'VP';
      case EndorsementCategory.ru:
        return 'RU';
      case EndorsementCategory.t:
        return 'T';
      case EndorsementCategory.p:
        return 'P';
      case EndorsementCategory.tw:
        return 'TW';
      case EndorsementCategory.modelRegister:
        return 'MODEL_REGISTER';
      case EndorsementCategory.nightRating:
        return 'NIGHT';
      case EndorsementCategory.instrumentRating:
        return 'IFR';
      case EndorsementCategory.other:
        return 'OTHER';
    }
  }

  static EndorsementCategory fromCode(String code) {
    final upper = code.toUpperCase();
    for (final cat in EndorsementCategory.values) {
      if (cat.code == upper || cat.name.toUpperCase() == upper) {
        return cat;
      }
    }
    return EndorsementCategory.other;
  }
}

