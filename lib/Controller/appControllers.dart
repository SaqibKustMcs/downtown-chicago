import 'package:get/get.dart';

class AppController extends GetxController {
  var isVisible = false.obs;
  var selectedBOttomTabIndex = 0.obs;
  var selectedIndexTabs = 0.obs;
  var ordersIndexTabs = 0.obs;

  var paymentmethod = true.obs;
  var cryptolist = false.obs;
  var scanPay = false.obs;
  var review = false.obs;
  var payWithCash = false.obs;
  var isPayWithCard = false.obs;

  var countryName = "".obs;
  var countryemojy = "".obs;

  var account = true.obs;
  var chatting = false.obs;
  var sales = true.obs;
  var offers = true.obs;
  var promotional = false.obs;
  var purchases = true.obs;
  var isDark = false.obs;
}
