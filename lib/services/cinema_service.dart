import 'package:book_my_seat/book_my_seat.dart';
import '../models/cinema_hall_model.dart';

class CinemaService {
  Future<CinemaHallModel> getHallConfiguration(String hallId) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return CinemaHallModel(
      hallId: hallId,
      hallName: 'Cinema Hall $hallId',
      rows: 8,
      seatsPerRow: 12,
      aisles: [
        AisleInfo(columnIndex: 3, type: AisleType.vertical),
        AisleInfo(columnIndex: 8, type: AisleType.vertical),
      ],
      vipRows: [6, 7],
      bookedSeats: {
        '3-5': SeatState.sold,
        '3-6': SeatState.sold,
        '4-5': SeatState.sold,
        '4-6': SeatState.sold,
      },
    );
  }

  Future<BookingResponse> bookSeats({
    required String hallId,
    required String movieId,
    required List<String> seatIds,
    required double totalAmount,
  }) async {
    await Future.delayed(const Duration(seconds: 1));

    return BookingResponse(
      success: true,
      bookingId: 'BK${DateTime.now().millisecondsSinceEpoch}',
      message: 'Seats booked successfully!',
    );
  }
}

class AisleInfo {
  final int columnIndex;
  final AisleType type;

  AisleInfo({required this.columnIndex, required this.type});
}

enum AisleType { vertical, horizontal }

class BookingResponse {
  final bool success;
  final String? bookingId;
  final String message;

  BookingResponse({
    required this.success,
    this.bookingId,
    required this.message,
  });
}
