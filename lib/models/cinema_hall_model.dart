import 'package:book_my_seat/book_my_seat.dart';
import '../services/cinema_service.dart';

class CinemaHallModel {
  final String hallId;
  final String hallName;
  final int rows;
  final int seatsPerRow;
  final List<AisleInfo> aisles;
  final List<int> vipRows;
  final Map<String, SeatState> bookedSeats;

  CinemaHallModel({
    required this.hallId,
    required this.hallName,
    required this.rows,
    required this.seatsPerRow,
    required this.aisles,
    required this.vipRows,
    required this.bookedSeats,
  });

  factory CinemaHallModel.fromJson(Map<String, dynamic> json) {
    return CinemaHallModel(
      hallId: json['hallId'] ?? '',
      hallName: json['hallName'] ?? '',
      rows: json['rows'] ?? 0,
      seatsPerRow: json['seatsPerRow'] ?? 0,
      aisles: (json['aisles'] as List<dynamic>?)
              ?.map((e) => AisleInfo(
                    columnIndex: e['columnIndex'] ?? 0,
                    type: e['type'] == 'horizontal'
                        ? AisleType.horizontal
                        : AisleType.vertical,
                  ))
              .toList() ??
          [],
      vipRows: (json['vipRows'] as List<dynamic>?)?.cast<int>() ?? [],
      bookedSeats: (json['bookedSeats'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              value == 'sold' ? SeatState.sold : SeatState.unselected,
            ),
          ) ??
          {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hallId': hallId,
      'hallName': hallName,
      'rows': rows,
      'seatsPerRow': seatsPerRow,
      'aisles': aisles
          .map((e) => {
                'columnIndex': e.columnIndex,
                'type': e.type == AisleType.horizontal ? 'horizontal' : 'vertical',
              })
          .toList(),
      'vipRows': vipRows,
      'bookedSeats': bookedSeats.map(
        (key, value) => MapEntry(
          key,
          value == SeatState.sold ? 'sold' : 'unselected',
        ),
      ),
    };
  }
}
