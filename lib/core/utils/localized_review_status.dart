import '../../l10n/app_localizations.dart';

/// Firestore `reviewStatus` maydoni uchun joriy tildagi yozuv.
String localizedReviewStatus(AppLocalizations l10n, String? reviewStatus) {
  switch (reviewStatus) {
    case 'reviewed':
      return l10n.submissionStatusReviewed;
    case 'returned':
      return l10n.submissionStatusReturned;
    case 'submitted':
    default:
      return l10n.submissionStatusSubmitted;
  }
}
