class TrafficSignInfo {
  final String id;
  final String group;
  final String name;
  final String meaning;
  final String shape;
  final String symbol;
  final String memoryTip;

  const TrafficSignInfo({
    required this.id,
    required this.group,
    required this.name,
    required this.meaning,
    required this.shape,
    required this.symbol,
    required this.memoryTip,
  });

  factory TrafficSignInfo.fromJson(Map<String, dynamic> json) => TrafficSignInfo(
        id: json['id'] as String,
        group: json['group'] as String,
        name: json['name'] as String,
        meaning: json['meaning'] as String,
        shape: json['shape'] as String,
        symbol: (json['symbol'] ?? '') as String,
        memoryTip: (json['memory_tip'] ?? '') as String,
      );
}
