class SignatoryConfig {
  final bool enableSignatory1;
  final String signatory1Title;
  final String signatory1Name;
  final bool enableSignatory2;
  final String signatory2Title;
  final String signatory2Name;
  final bool enableSignatory3;
  final String? signatory3Title;
  final String? signatory3Name;

  const SignatoryConfig({
    this.enableSignatory1 = true,
    this.signatory1Title = 'Signature of Driver',
    this.signatory1Name = 'Rajesh Kumar',
    this.enableSignatory2 = true,
    this.signatory2Title = 'Controlling Officer (EE / SE)',
    this.signatory2Name = 'Dr. S. K. Verma (EE)',
    this.enableSignatory3 = false,
    this.signatory3Title = 'Counter-Signed (Superintending Engineer / HOD)',
    this.signatory3Name = 'Anjali Sharma, IAS',
  });

  SignatoryConfig copyWith({
    bool? enableSignatory1,
    String? signatory1Title,
    String? signatory1Name,
    bool? enableSignatory2,
    String? signatory2Title,
    String? signatory2Name,
    bool? enableSignatory3,
    String? signatory3Title,
    String? signatory3Name,
  }) {
    return SignatoryConfig(
      enableSignatory1: enableSignatory1 ?? this.enableSignatory1,
      signatory1Title: signatory1Title ?? this.signatory1Title,
      signatory1Name: signatory1Name ?? this.signatory1Name,
      enableSignatory2: enableSignatory2 ?? this.enableSignatory2,
      signatory2Title: signatory2Title ?? this.signatory2Title,
      signatory2Name: signatory2Name ?? this.signatory2Name,
      enableSignatory3: enableSignatory3 ?? this.enableSignatory3,
      signatory3Title: signatory3Title ?? this.signatory3Title,
      signatory3Name: signatory3Name ?? this.signatory3Name,
    );
  }
}
