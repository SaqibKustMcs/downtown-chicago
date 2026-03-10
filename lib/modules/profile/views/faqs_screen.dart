import 'package:flutter/material.dart';
import 'package:downtown/core/widgets/animated_list_item.dart';
import 'package:downtown/core/utils/tabler_icons_helper.dart';
import 'package:downtown/modules/widgets/top_navigation_bar.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class FAQ {
  final String question;
  final String answer;

  const FAQ({required this.question, required this.answer});
}

class FAQsScreen extends StatefulWidget {
  const FAQsScreen({super.key});

  @override
  State<FAQsScreen> createState() => _FAQsScreenState();
}

class _FAQsScreenState extends State<FAQsScreen> {
  int? _expandedIndex;

  static const List<FAQ> _faqs = [
    FAQ(
      question: 'How do I place an order?',
      answer:
          'You can place an order by browsing restaurants, selecting items, adding them to your cart, and proceeding to checkout. You can choose your payment method and delivery address before confirming the order.',
    ),
    FAQ(
      question: 'What payment methods are accepted?',
      answer:
          'We accept cash on delivery, credit cards, debit cards, and digital wallets. You can add and manage your payment methods in the Payment Method section of your profile.',
    ),
    FAQ(
      question: 'How long does delivery take?',
      answer:
          'Delivery time varies depending on the restaurant and your location. Typically, orders are delivered within 20-40 minutes. You can see the estimated delivery time when selecting a restaurant.',
    ),
    FAQ(
      question: 'Can I cancel my order?',
      answer:
          'Yes, you can cancel your order if it hasn\'t been prepared yet. Go to "My Orders" and tap on the order you want to cancel. A cancellation confirmation will be shown.',
    ),
    FAQ(
      question: 'How do I track my order?',
      answer:
          'Once your order is confirmed, you can track it in real-time from the "My Orders" section. Tap on an ongoing order to see the live tracking map and estimated delivery time.',
    ),
    FAQ(
      question: 'What if I receive the wrong order?',
      answer:
          'If you receive the wrong order, please contact our customer support immediately through the chat feature. We will resolve the issue and provide a refund or replacement.',
    ),
    FAQ(
      question: 'Can I modify my order after placing it?',
      answer: 'Unfortunately, orders cannot be modified once placed. However, you can cancel the order and place a new one if the restaurant hasn\'t started preparing it yet.',
    ),
    FAQ(
      question: 'How do I add a delivery address?',
      answer: 'You can add or edit delivery addresses in the "Addresses" section of your profile. You can also set a default address for faster checkout.',
    ),
    FAQ(
      question: 'Are there any delivery charges?',
      answer:
          'Delivery charges vary by restaurant and location. Some restaurants offer free delivery, while others may charge a small fee. The delivery cost is shown before you place your order.',
    ),
    FAQ(
      question: 'How do I apply a promo code?',
      answer: 'You can apply promo codes during checkout. Enter your code in the promo code field and tap "Apply" to see the discount applied to your order total.',
    ),
    FAQ(
      question: 'What is the minimum order amount?',
      answer: 'Minimum order amounts vary by restaurant. You can see the minimum order requirement when viewing a restaurant\'s details.',
    ),
    FAQ(
      question: 'How do I rate a restaurant?',
      answer:
          'After receiving your order, you can rate and review the restaurant from the "My Orders" section. Tap on a completed order and select "Rate" to share your experience.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Navigation
            TopNavigationBar(title: 'FAQs'),

            // FAQs List
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: Sizes.s12, vertical: Sizes.s16),
                itemCount: _faqs.length,
                itemBuilder: (context, index) {
                  return AnimatedListItem(
                    index: index,
                    child: _buildFAQItem(_faqs[index], index),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(FAQ faq, int index) {
    final isExpanded = _expandedIndex == index;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: Sizes.s12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(Sizes.s16),
          border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: Sizes.s16, vertical: Sizes.s8),
          childrenPadding: const EdgeInsets.fromLTRB(Sizes.s16, Sizes.s0, Sizes.s16, Sizes.s16),
          initiallyExpanded: isExpanded,
          onExpansionChanged: (expanded) {
            setState(() {
              _expandedIndex = expanded ? index : null;
            });
          },
          title: Row(
            children: [
              Icon(TablerIconsHelper.help, color: const Color(0xFFFF6B35), size: Sizes.s20),
              const SizedBox(width: Sizes.s12),
              Expanded(
                child: Text(
                  faq.question,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ],
          ),
          trailing: Icon(
            isExpanded ? TablerIconsHelper.arrowDown : TablerIconsHelper.chevronRight,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            size: Sizes.s20,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.only(left: Sizes.s32),
              child: Text(faq.answer, style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7), height: 1.5)),
            ),
          ],
        ),
      ),
    );
  }
}
