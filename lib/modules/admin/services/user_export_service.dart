import 'dart:io';
import 'package:downtown/modules/auth/models/user_model.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class UserExportService {
  UserExportService._();
  static final UserExportService instance = UserExportService._();

  /// Export users to CSV format
  Future<bool> exportUsersToCSV(List<UserModel> users, {String? filename}) async {
    try {
      // Generate CSV content
      final csvContent = _generateCSVContent(users);
      
      // Create temporary file
      final directory = await getTemporaryDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/${filename ?? 'users_export_$timestamp'}.csv');
      
      // Write CSV content to file
      await file.writeAsString(csvContent);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'User Export',
        subject: 'Users Export CSV',
      );
      
      return true;
    } catch (e) {
      print('Error exporting users to CSV: $e');
      return false;
    }
  }

  /// Generate CSV content from users list
  String _generateCSVContent(List<UserModel> users) {
    final buffer = StringBuffer();
    
    // CSV Header
    buffer.writeln('Name,Email,Phone,User Type,Email Verified,Online Status,Availability,Vehicle Type,Vehicle Number,Account Created,Last Updated');
    
    // CSV Rows
    for (final user in users) {
      final row = [
        _escapeCSV(user.name ?? 'N/A'),
        _escapeCSV(user.email),
        _escapeCSV(user.phoneNumber ?? 'N/A'),
        _escapeCSV(_getUserTypeLabel(user.userType)),
        _escapeCSV(user.emailVerified == true ? 'Yes' : 'No'),
        _escapeCSV(user.userType == UserType.rider 
            ? (user.isOnline == true ? 'Online' : 'Offline')
            : 'N/A'),
        _escapeCSV(user.userType == UserType.rider
            ? (user.isAvailable == true ? 'Available' : 'Unavailable')
            : 'N/A'),
        _escapeCSV(user.vehicleType ?? 'N/A'),
        _escapeCSV(user.vehicleNumber ?? 'N/A'),
        _escapeCSV(user.createdAt != null 
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(user.createdAt!)
            : 'N/A'),
        _escapeCSV(user.updatedAt != null
            ? DateFormat('yyyy-MM-dd HH:mm:ss').format(user.updatedAt!)
            : 'N/A'),
      ];
      
      buffer.writeln(row.join(','));
    }
    
    return buffer.toString();
  }

  /// Escape CSV special characters
  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Get user type label
  String _getUserTypeLabel(UserType userType) {
    switch (userType) {
      case UserType.admin:
        return 'Admin';
      case UserType.rider:
        return 'Rider';
      case UserType.customer:
        return 'Customer';
    }
  }
}
