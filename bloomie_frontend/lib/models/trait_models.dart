class GeneticTrait {
  final String traitName;
  final String gene;
  final String confidence;
  final String description;
  
  GeneticTrait({
    required this.traitName,
    required this.gene,
    required this.confidence,
    required this.description,
  });
  
  factory GeneticTrait.fromJson(Map<String, dynamic> json) {
    return GeneticTrait(
      traitName: json['trait_name'] ?? '',
      gene: json['gene'] ?? '',
      confidence: json['confidence'] ?? '',
      description: json['description'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'trait_name': traitName,
      'gene': gene,
      'confidence': confidence,
      'description': description,
    };
  }
}