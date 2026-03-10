import 'package:flutter/material.dart';
import 'package:downtown/styles/layouts/sizes.dart';
import 'package:downtown/styles/typography/app_text_styles.dart';

class OrderErrorWidget extends StatelessWidget {
  final Object? error;
  final VoidCallback? onRetry;

  const OrderErrorWidget({
    super.key,
    this.error,
    this.onRetry,
  });

  /// Extract index creation URL from Firestore error message
  String? _extractIndexUrl(String errorMessage) {
    // Firestore errors typically contain a URL like:
    // https://console.firebase.google.com/v1/r/project/.../firestore/indexes?create_composite=...
    // or
    // https://console.firebase.google.com/project/.../firestore/indexes?create_composite=...
    final urlPattern = RegExp(
      r'https://console\.firebase\.google\.com/[^\s,)]+',
      caseSensitive: false,
    );
    final match = urlPattern.firstMatch(errorMessage);
    return match?.group(0);
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = error?.toString() ?? 'Unknown error';
    final isIndexError = errorMessage.contains('index') || 
                         errorMessage.contains('requires an index') ||
                         errorMessage.contains('FAILED_PRECONDITION') ||
                         errorMessage.contains('failed-precondition') ||
                         errorMessage.contains('firebase.google.com');
    
    final indexUrl = _extractIndexUrl(errorMessage);
    
    // Debug: Log extracted URL for troubleshooting
    if (isIndexError && indexUrl != null) {
      debugPrint('Extracted index URL: $indexUrl');
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Sizes.s16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: Sizes.s64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: Sizes.s16),
            Text(
              'Error loading orders',
              style: AppTextStyles.heading3.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: Sizes.s16),
            if (isIndexError)
              Column(
                children: [
                  Text(
                    'Firestore Index Required',
                    style: AppTextStyles.heading4.copyWith(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Sizes.s16),
                  if (indexUrl != null) ...[
                    Text(
                      'Index creation URL found in error message.',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Sizes.s8),
                    SelectableText(
                      indexUrl!,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Sizes.s8),
                    Text(
                      'Copy this URL and open it in your browser to create the index automatically.',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: Sizes.s16),
                    const Divider(),
                    const SizedBox(height: Sizes.s16),
                    Text(
                      'Or create these indexes manually in Firebase Console:\n\n',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  ] else
                    Text(
                      'Create these indexes manually in Firebase Console:\n\n',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.left,
                    ),
                  Text(
                    '1. orders: customerId (Ascending) + createdAt (Descending)\n'
                    '2. orders: adminId (Ascending) + createdAt (Descending)\n'
                    '3. orders: riderId (Ascending) + createdAt (Descending)\n'
                    '4. orders: riderId (Ascending) + status (Ascending) + createdAt (Descending)',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    textAlign: TextAlign.left,
                  ),
                  const SizedBox(height: Sizes.s8),
                  Text(
                    'See FIREBASE_INDEXES.md for detailed instructions.',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              )
            else
              Text(
                errorMessage.length > 200 
                  ? '${errorMessage.substring(0, 200)}...'
                  : errorMessage,
                style: AppTextStyles.bodySmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            if (onRetry != null) ...[
              const SizedBox(height: Sizes.s24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B35),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
