import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:downtown/core/utils/currency_formatter.dart';
import 'package:downtown/modules/orders/models/order_model.dart';
import 'package:downtown/core/firebase/firebase_service.dart';

class PrintService {
  PrintService._();
  static final PrintService instance = PrintService._();

  /// Print KOT (Kitchen Order Ticket)
  Future<void> printKOT({
    required OrderModel order,
    required BuildContext context,
    required Function(bool) onPrintStatusChanged,
  }) async {
    try {
      final pdf = await _generateKOTPDF(order);
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      
      // Mark KOT as printed
      await _markAsPrinted(order.id, 'kot');
      onPrintStatusChanged(true);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('KOT printed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing KOT: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Print Bill
  Future<void> printBill({
    required OrderModel order,
    required BuildContext context,
    String? riderName,
    required Function(bool) onPrintStatusChanged,
  }) async {
    try {
      final pdf = await _generateBillPDF(order, riderName);
      
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );
      
      // Mark Bill as printed
      await _markAsPrinted(order.id, 'bill');
      onPrintStatusChanged(true);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill printed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing Bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Generate KOT PDF
  Future<pw.Document> _generateKOTPDF(OrderModel order) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');
    final orderNo = order.id.substring(0, 8).toUpperCase();
    final orderTypeText = order.orderType == OrderType.takeaway ? 'Takeaway' : 'Delivery';

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'KITCHEN ORDER TICKET',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                  ],
                ),
              ),
              
              pw.Divider(),
              pw.SizedBox(height: 8),
              
              // Order No
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Order No:', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    orderNo,
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              
              // Type
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Type:', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    orderTypeText,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              
              // Date & Time
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date:', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    order.createdAt != null
                        ? dateFormat.format(order.createdAt!)
                        : 'N/A',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              
              pw.Divider(),
              pw.SizedBox(height: 8),
              
              // Items Header
              pw.Text(
                'ITEMS:',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              
              // Items List
              ...order.items.map((item) {
                final itemName = item['name'] as String? ?? 'Item';
                final quantity = item['quantity'] as int? ?? 0;
                final variation = item['selectedVariation'] as String?;
                final flavor = item['selectedFlavor'] as String?;
                
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '$quantity x',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                itemName,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              if (variation != null) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  '  Size: $variation',
                                  style: pw.TextStyle(fontSize: 9),
                                ),
                              ],
                              if (flavor != null) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  '  Flavor: $flavor',
                                  style: pw.TextStyle(fontSize: 9),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                  ],
                );
              }),
              
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 4),
              
              // Footer
              pw.Center(
                child: pw.Text(
                  'Thank You!',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Generate Bill PDF
  Future<pw.Document> _generateBillPDF(OrderModel order, String? riderName) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy hh:mm a');
    final orderNo = order.id.substring(0, 8).toUpperCase();
    final orderTypeText = order.orderType == OrderType.takeaway ? 'Takeaway' : 'Delivery';
    final paymentStatus = order.paymentMethod == 'cash_on_delivery'
        ? 'Pay via Cash on Delivery'
        : 'Paid Online';
    
    // Calculate tax (assuming 5% tax, adjust as needed)
    final taxRate = 0.05;
    final taxAmount = order.subtotal * taxRate;
    // For takeaway orders, no delivery fee
    final totalWithTax = order.subtotal + taxAmount + (order.orderType == OrderType.delivery ? order.deliveryFee : 0.0);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(80 * PdfPageFormat.mm, double.infinity),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      order.restaurantName ?? 'RESTAURANT',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'BILL',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                  ],
                ),
              ),
              
              pw.Divider(),
              pw.SizedBox(height: 8),
              
              // Order No
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Order No:', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    orderNo,
                    style: pw.TextStyle(
                      fontSize: 11,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              
              // Order ID
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Order ID:', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    order.id.substring(0, 12).toUpperCase(),
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              
              // Type
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Type:', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    orderTypeText,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              
              // Date & Time
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Date:', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    order.createdAt != null
                        ? dateFormat.format(order.createdAt!)
                        : 'N/A',
                    style: pw.TextStyle(fontSize: 9),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              
              pw.Divider(),
              pw.SizedBox(height: 8),
              
              // Items Header
              pw.Text(
                'ITEMS:',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 6),
              
              // Items List
              ...order.items.map((item) {
                final itemName = item['name'] as String? ?? 'Item';
                final quantity = item['quantity'] as int? ?? 0;
                final unitPrice = (item['unitPrice'] as num?)?.toDouble() ?? 0.0;
                final totalPrice = quantity * unitPrice;
                final variation = item['selectedVariation'] as String?;
                final flavor = item['selectedFlavor'] as String?;
                
                return pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          '$quantity x',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(width: 4),
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                itemName,
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              if (variation != null) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  '  Size: $variation',
                                  style: pw.TextStyle(fontSize: 9),
                                ),
                              ],
                              if (flavor != null) ...[
                                pw.SizedBox(height: 2),
                                pw.Text(
                                  '  Flavor: $flavor',
                                  style: pw.TextStyle(fontSize: 9),
                                ),
                              ],
                            ],
                          ),
                        ),
                        pw.Text(
                          CurrencyFormatter.format(totalPrice),
                          style: pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 6),
                  ],
                );
              }),
              
              pw.SizedBox(height: 8),
              pw.Divider(),
              pw.SizedBox(height: 8),
              
              // Price Breakdown
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Items Total:', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    CurrencyFormatter.format(order.subtotal),
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Tax (5%):', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    CurrencyFormatter.format(taxAmount),
                    style: pw.TextStyle(fontSize: 10),
                  ),
                ],
              ),
              pw.SizedBox(height: 4),
              
              // Only show delivery charges for delivery orders
              if (order.orderType == OrderType.delivery)
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Delivery Charges:', style: pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      CurrencyFormatter.formatWithFree(order.deliveryFee),
                      style: pw.TextStyle(fontSize: 10),
                    ),
                  ],
                ),
              pw.SizedBox(height: 8),
              
              pw.Divider(),
              pw.SizedBox(height: 8),
              
              // Total
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL BILL:',
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Text(
                    CurrencyFormatter.format(totalWithTax),
                    style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 8),
              
              pw.Divider(),
              pw.SizedBox(height: 8),
              
              // Payment Status
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Bill:', style: pw.TextStyle(fontSize: 10)),
                  pw.Text(
                    paymentStatus,
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
              
              // Rider Name
              if (riderName != null && riderName.isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Assigned Rider:', style: pw.TextStyle(fontSize: 10)),
                    pw.Text(
                      riderName,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
              
              pw.SizedBox(height: 12),
              pw.Divider(),
              pw.SizedBox(height: 8),
              
              // Footer
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Thank You!',
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Visit Again',
                      style: pw.TextStyle(fontSize: 9),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }

  /// Mark order as printed (KOT or Bill)
  Future<void> _markAsPrinted(String orderId, String printType) async {
    try {
      await FirebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .update({
        '${printType}Printed': true,
        '${printType}PrintedAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });
    } catch (e) {
      debugPrint('Error marking order as printed: $e');
    }
  }

  /// Check if order has been printed
  Future<Map<String, bool>> checkPrintStatus(String orderId) async {
    try {
      final doc = await FirebaseService.firestore
          .collection('orders')
          .doc(orderId)
          .get();
      
      if (!doc.exists) {
        return {'kotPrinted': false, 'billPrinted': false};
      }
      
      final data = doc.data() as Map<String, dynamic>;
      return {
        'kotPrinted': data['kotPrinted'] as bool? ?? false,
        'billPrinted': data['billPrinted'] as bool? ?? false,
      };
    } catch (e) {
      debugPrint('Error checking print status: $e');
      return {'kotPrinted': false, 'billPrinted': false};
    }
  }
}
