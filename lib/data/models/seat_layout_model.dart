import 'dart:convert';

class SeatLayoutModel {
  final String hallId;
  final String hallName;
  final String movieTitle;
  final String showtime;
  final String showDate;
  final int totalRows;
  final int totalColumns;
  final PricingModel pricing;
  final List<AisleModel> aisles;
  final List<int> vipRows;
  final List<SeatPosition> bookedSeats;
  final List<List<String>> seatLayout;

  SeatLayoutModel({
    required this.hallId,
    required this.hallName,
    required this.movieTitle,
    required this.showtime,
    required this.showDate,
    required this.totalRows,
    required this.totalColumns,
    required this.pricing,
    required this.aisles,
    required this.vipRows,
    required this.bookedSeats,
    required this.seatLayout,
  });

  factory SeatLayoutModel.fromJson(Map<String, dynamic> json) {
    return SeatLayoutModel(
      hallId: json['hallId'] ?? '',
      hallName: json['hallName'] ?? '',
      movieTitle: json['movieTitle'] ?? '',
      showtime: json['showtime'] ?? '',
      showDate: json['showDate'] ?? '',
      totalRows: json['totalRows'] ?? 0,
      totalColumns: json['totalColumns'] ?? 0,
      pricing: PricingModel.fromJson(json['pricing'] ?? {}),
      aisles: (json['aisles'] as List<dynamic>?)
              ?.map((e) => AisleModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      vipRows: (json['vipRows'] as List<dynamic>?)?.map((e) => e as int).toList() ?? [],
      bookedSeats: (json['bookedSeats'] as List<dynamic>?)
              ?.map((e) => SeatPosition.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      seatLayout: (json['seatLayout'] as List<dynamic>?)
              ?.map((row) => (row as List<dynamic>).map((seat) => seat.toString()).toList())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hallId': hallId,
      'hallName': hallName,
      'movieTitle': movieTitle,
      'showtime': showtime,
      'showDate': showDate,
      'totalRows': totalRows,
      'totalColumns': totalColumns,
      'pricing': pricing.toJson(),
      'aisles': aisles.map((e) => e.toJson()).toList(),
      'vipRows': vipRows,
      'bookedSeats': bookedSeats.map((e) => e.toJson()).toList(),
      'seatLayout': seatLayout,
    };
  }

  factory SeatLayoutModel.fromJsonString(String jsonString) {
    final Map<String, dynamic> jsonMap = json.decode(jsonString);
    return SeatLayoutModel.fromJson(jsonMap);
  }

  bool isSeatBooked(int row, int col) {
    return bookedSeats.any((seat) => seat.row == row && seat.col == col);
  }

  bool isAisle(int col) {
    return aisles.any((aisle) => aisle.columnIndex == col);
  }

  bool isVIPRow(int row) {
    return vipRows.contains(row);
  }

  double getSeatPrice(int row) {
    return isVIPRow(row) ? pricing.vip : pricing.regular;
  }

  String getSeatStatus(int row, int col) {
    if (row >= seatLayout.length || col >= seatLayout[row].length) {
      return 'empty';
    }
    return seatLayout[row][col];
  }
}

class PricingModel {
  final double regular;
  final double vip;

  PricingModel({
    required this.regular,
    required this.vip,
  });

  factory PricingModel.fromJson(Map<String, dynamic> json) {
    return PricingModel(
      regular: (json['regular'] ?? 50.0).toDouble(),
      vip: (json['vip'] ?? 150.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'regular': regular,
      'vip': vip,
    };
  }
}

class AisleModel {
  final int columnIndex;
  final String name;

  AisleModel({
    required this.columnIndex,
    required this.name,
  });

  factory AisleModel.fromJson(Map<String, dynamic> json) {
    return AisleModel(
      columnIndex: json['columnIndex'] ?? 0,
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'columnIndex': columnIndex,
      'name': name,
    };
  }
}

class SeatPosition {
  final int row;
  final int col;

  SeatPosition({
    required this.row,
    required this.col,
  });

  factory SeatPosition.fromJson(Map<String, dynamic> json) {
    return SeatPosition(
      row: json['row'] ?? 0,
      col: json['col'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'row': row,
      'col': col,
    };
  }

  String get key => '$row-$col';
}

class SelectedSeatInfo {
  final int row;
  final int col;
  final String label;
  final double price;
  final bool isVIP;

  SelectedSeatInfo({
    required this.row,
    required this.col,
    required this.label,
    required this.price,
    required this.isVIP,
  });

  String get key => '$row-$col';
}
