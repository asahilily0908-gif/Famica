// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Famica';

  @override
  String get appTagline => 'Record your efforts in 10 seconds';

  @override
  String get navRecord => 'Record';

  @override
  String get navCouple => 'Couple';

  @override
  String get navLetter => 'Letters';

  @override
  String get navSettings => 'Settings';

  @override
  String get you => 'You';

  @override
  String get partner => 'Partner';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get close => 'Close';

  @override
  String get error => 'Error';

  @override
  String get loading => 'Loading...';

  @override
  String get logout => 'Log out';

  @override
  String get unset => 'Not set';

  @override
  String get uncategorized => 'Uncategorized';

  @override
  String get other => 'Other';

  @override
  String get all => 'All';

  @override
  String get send => 'Send';

  @override
  String get copy => 'Copy';

  @override
  String get share => 'Share';

  @override
  String get join => 'Join';

  @override
  String get members => 'Members';

  @override
  String get today => 'This month';

  @override
  String get task => 'Task';

  @override
  String get authEmailHint => 'example@mail.com';

  @override
  String get authEmailLabel => 'Email';

  @override
  String get authPasswordLabel => 'Password';

  @override
  String get authPasswordHint => '6 or more characters';

  @override
  String get authNicknameLabel => 'Nickname';

  @override
  String get authNicknameHint => 'e.g. Alex';

  @override
  String get authNicknameHelper => 'This name will be displayed in the app';

  @override
  String get authHasInviteCode => 'I have an invite code';

  @override
  String get authInviteCodeLabel => 'Invite code';

  @override
  String get authInviteCodeHint => 'e.g. ABC123';

  @override
  String get authInviteCodeHelper => 'Code received from your partner';

  @override
  String get authHouseholdNameLabel => 'Couple / Household name';

  @override
  String get authHouseholdNameHint => 'e.g. Alex & Sam';

  @override
  String get authHouseholdNameHelper => 'A group name shared between you two';

  @override
  String get authSignUp => 'Sign up';

  @override
  String get authLoginOrSignUp => 'Log in / Sign up';

  @override
  String get authSwitchToLogin => 'Log in with existing account';

  @override
  String get authSignUpNote => '* Your nickname will be displayed in the app';

  @override
  String get authLoginNote =>
      '* Existing users will log in,\nnew users will be registered automatically';

  @override
  String get authErrorEmptyFields => 'Please enter your email and password';

  @override
  String get authErrorEmptyNickname => 'Please enter a nickname';

  @override
  String get authErrorEmptyHousehold => 'Please enter a couple name';

  @override
  String get authErrorInvalidEmail => 'Invalid email format';

  @override
  String get authErrorWeakPassword => 'Password must be at least 6 characters';

  @override
  String get authErrorUserNotFound =>
      'Account not found. Enter a nickname to sign up';

  @override
  String get authErrorWrongPassword => 'Incorrect password';

  @override
  String get authErrorDisabled => 'This account has been disabled';

  @override
  String get authErrorTooMany => 'Too many requests. Please try again later';

  @override
  String get authErrorNetwork => 'Network error occurred';

  @override
  String get authErrorLogin => 'Login error';

  @override
  String get authErrorUnexpected => 'An unexpected error occurred';

  @override
  String get authErrorEmailInUse => 'This email is already in use';

  @override
  String get authErrorWeakPasswordSignUp =>
      'Password is too weak. Please use a stronger password';

  @override
  String get authErrorOperationNotAllowed =>
      'Email/password sign-in is not enabled';

  @override
  String get authErrorSignUp => 'Sign up error';

  @override
  String get authLoginSuccess => 'Successfully logged in';

  @override
  String get authSignUpSuccess => 'Registration complete! Welcome to Famica!';

  @override
  String get authInviteSuccess => 'Registration via invite code complete!';

  @override
  String get authInviteNotFound => 'Invite code not found';

  @override
  String get authInviteUsed => 'This invite code has already been used';

  @override
  String get authErrorCreateUser => 'Failed to create user';

  @override
  String get authErrorHouseholdNotFound => 'Household not found';

  @override
  String get mainInitSetup => 'Initial setup...';

  @override
  String get mainCreatingUser => 'Creating user information';

  @override
  String get mainLoadingUser => 'Loading user information...';

  @override
  String get mainPreparingHousehold => 'Preparing household info...';

  @override
  String get mainWaitingHousehold => 'Waiting for household setup';

  @override
  String get mainErrorOccurred => 'An error occurred';

  @override
  String get mainFirebaseError => 'Firebase initialization error';

  @override
  String get mainAuthError => 'Authentication error';

  @override
  String get quickRecord => 'Quick record';

  @override
  String get quickRecordPanelEdit => 'Edit panels';

  @override
  String get quickRecordTodayEffort => 'Today\'s efforts';

  @override
  String quickRecordCountTimes(int count) {
    return '$count times';
  }

  @override
  String quickRecordMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String get quickRecordRecentRecords => 'Recent records';

  @override
  String get quickRecordSeeAll => 'See all';

  @override
  String get quickRecordNoRecords => 'No records yet';

  @override
  String get quickRecordNoName => 'Unknown';

  @override
  String get quickRecordAdded => 'Record added!';

  @override
  String get quickRecordThanks => 'Thank you sent!';

  @override
  String get quickRecordCostRecord => 'Record a cost';

  @override
  String get quickRecordSelectTime => 'Select time';

  @override
  String quickRecordError(String error) {
    return 'Error: $error';
  }

  @override
  String get costRecordTitle => 'Record cost';

  @override
  String get costRecordAmount => 'Amount';

  @override
  String get costRecordAmountHint => '1000';

  @override
  String get costRecordPurpose => 'Purpose';

  @override
  String get costRecordPurposeHint => 'e.g. Groceries, supplies, transport';

  @override
  String get costRecordPayer => 'Paid by';

  @override
  String get costRecordEmptyAmount => 'Please enter an amount';

  @override
  String get costRecordInvalidAmount => 'Please enter a valid amount';

  @override
  String get costRecordSuccess => 'Cost recorded!';

  @override
  String get costRecordFailed => 'Failed to save';

  @override
  String get costRecordNoPurpose => 'No purpose';

  @override
  String get coupleActionTip => 'Action tip';

  @override
  String get coupleThisMonth => 'This month';

  @override
  String get coupleSendGratitude => 'Send a thank you';

  @override
  String get coupleSendGratitudeDesc =>
      'Share your appreciation with your partner';

  @override
  String get coupleGratitudeReceived => 'You received a thank you card';

  @override
  String get coupleTapToRead => 'Tap to read';

  @override
  String get coupleMonthlyBreakdown =>
      'This month\'s chore breakdown (by category)';

  @override
  String get coupleMonthlyCost => 'This month\'s costs (expenses)';

  @override
  String get coupleTotal => 'Total';

  @override
  String get coupleNoSuggestion => 'No suggestions for this month yet';

  @override
  String get coupleSuggestion => 'Suggestion';

  @override
  String get coupleSuggestionOverworked =>
      'It looks like the load is leaning a bit toward you.\nMaybe let your partner take over sometimes and relax.';

  @override
  String get coupleSuggestionPartnerOverworked =>
      'It looks like your partner is carrying a bit more.\nConsider sharing your gratitude with them.';

  @override
  String get coupleSuggestionBalanced => 'Great cooking balance!\nKeep it up!';

  @override
  String get couplePartnerNotFound => 'Partner not found';

  @override
  String get coupleSendGratitudeCard => 'Send a thank you card';

  @override
  String get coupleSendTo => 'To:';

  @override
  String get coupleMessage => 'Message';

  @override
  String get coupleMessageHint => 'e.g. Thanks for always doing the dishes!';

  @override
  String get coupleEmptyMessage => 'Please enter a message';

  @override
  String get coupleSendFailed => 'Failed to send';

  @override
  String get letterTitle => 'Thank you messages from your partner';

  @override
  String get letterPleaseLogin => 'Please log in';

  @override
  String get letterNoMessages => 'No messages received yet';

  @override
  String get letterUnread => 'Unread';

  @override
  String letterFromUser(String name) {
    return 'From $name';
  }

  @override
  String get settingsInvitePartner => 'Invite partner';

  @override
  String get settingsChangeNickname => 'Change nickname';

  @override
  String get settingsPrivacyPolicy => 'Privacy policy';

  @override
  String get settingsHelp => 'Help & support';

  @override
  String get settingsTerms => 'Terms of service';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteConfirm => 'Delete your account?';

  @override
  String get settingsDeleteWarning =>
      'The following information will be permanently deleted';

  @override
  String get settingsDeleteRecords => '• All records';

  @override
  String get settingsDeletePartner => '• Partner shared information';

  @override
  String get settingsDeleteIrreversible => 'This action cannot be undone';

  @override
  String get settingsDeleteButton => 'Delete';

  @override
  String get settingsDeleting => 'Deleting account...';

  @override
  String get settingsDeleteUserNotFound => 'User not found';

  @override
  String get settingsDeleteFirestoreFailed => 'Failed to delete Firestore data';

  @override
  String get settingsDeleteFailed => 'Delete failed';

  @override
  String get settingsReauthRequired => 'Re-authentication required';

  @override
  String get settingsReauthFailed => 'Re-authentication failed';

  @override
  String get settingsReauthError => 'Error during re-authentication';

  @override
  String get settingsReauthInstruction =>
      'If you logged in with email/password,\nplease log out and log in again\nbefore deleting your account.';

  @override
  String get settingsUnsupportedAuth => 'Unsupported authentication method';

  @override
  String get settingsLogoutConfirm =>
      'Log out?\nYou will need to log in again.';

  @override
  String get settingsLogoutButton => 'Log out';

  @override
  String get settingsNicknameChange => 'Change nickname';

  @override
  String get settingsNicknameInput => 'Enter nickname';

  @override
  String get settingsNicknameEmpty => 'Please enter a nickname';

  @override
  String get settingsNicknameSaved => 'Changes saved';

  @override
  String get settingsNicknameError => 'An error occurred';

  @override
  String get settingsNicknameNote =>
      'Nickname changes are reflected across all screens';

  @override
  String get settingsSaveChanges => 'Save changes';

  @override
  String get inviteTitle => 'Invite partner';

  @override
  String get inviteDescription => 'Invite your partner to Famica!';

  @override
  String get inviteYourCode => 'Your invite code';

  @override
  String get inviteCopied => 'Invite code copied';

  @override
  String get inviteShareSubject => 'Invite to Famica';

  @override
  String get inviteEnterCode => 'Enter invite code';

  @override
  String get inviteEnterCodeDesc =>
      'Enter the 6-digit code\nyou received from your partner';

  @override
  String get inviteCodeHint => 'ABC123';

  @override
  String get inviteEmptyCode => 'Please enter an invite code';

  @override
  String get inviteInvalidCode => 'Invalid invite code';

  @override
  String get inviteJoinSuccess => 'Joined successfully!';

  @override
  String get inviteJoinFailed => 'Failed to join';

  @override
  String get inviteNoMembers => 'No members yet';

  @override
  String get inviteNoPartner => 'No partner yet';

  @override
  String get inviteNoPartnerDesc =>
      'Get an invite code from your partner\nand join';

  @override
  String get invitePartnerCardTitle =>
      'Invite your partner and\nvisualize your shared efforts';

  @override
  String get invitePartnerCardDesc =>
      'Just send an invite link to start sharing';

  @override
  String get invitePartnerCardButton => 'Share invite link';

  @override
  String get categoryEditTitle => 'Edit categories';

  @override
  String get categoryAddTitle => 'Add category';

  @override
  String get categoryEmpty => 'No categories';

  @override
  String get categoryEmptyHint => 'Tap + to add a category';

  @override
  String get categoryMaxReached => 'Maximum 12 categories';

  @override
  String get categoryAdded => 'Category added';

  @override
  String get categoryUpdated => 'Category updated';

  @override
  String get categoryDeleteConfirm => 'Delete this category?';

  @override
  String get categoryDeleteNote =>
      'Records linked to this category will remain.';

  @override
  String get categoryDeleted => 'Category deleted';

  @override
  String get categoryStandardNote =>
      '* This is a default category and cannot be deleted';

  @override
  String get categoryOrderSaved => 'Order saved';

  @override
  String get categoryEmoji => 'Emoji';

  @override
  String get categorySelectEmoji => 'Tap to select an icon';

  @override
  String get categorySelectEmojiTitle => 'Select icon';

  @override
  String get categoryName => 'Category name';

  @override
  String get categoryNameHint => 'e.g. Lunch prep';

  @override
  String get categoryDuration => 'Duration (min)';

  @override
  String get categorySelectDuration => 'Select duration';

  @override
  String get categoryNameEmpty => 'Please enter a category name';

  @override
  String get categoryEmojiEmpty => 'Please select an emoji';

  @override
  String get categoryInvalidTime => 'Please enter a valid time';

  @override
  String get gratitudeHistoryTitle => 'Received thanks';

  @override
  String get gratitudeEmpty => 'No thank you cards yet';

  @override
  String get gratitudeSender => 'From';

  @override
  String get nicknameChangeTitle => 'Change nickname';

  @override
  String get nicknameLabel => 'Nickname';

  @override
  String get nicknameInputHint => 'Enter nickname';

  @override
  String get nicknameEmpty => 'Please enter a nickname';

  @override
  String get nicknameSaved => 'Changes saved';

  @override
  String get nicknameNote =>
      'Nickname changes are reflected across all screens';

  @override
  String get albumTitle => 'Album';

  @override
  String get albumOurAlbum => 'Our album';

  @override
  String get albumRecordsOnly => 'Records only';

  @override
  String get albumGratitudeOnly => 'Thanks only';

  @override
  String get albumNoItems => 'Nothing in the album yet';

  @override
  String get albumNoItemsDesc => 'Records and thanks will\nappear in the album';

  @override
  String get albumRecord => 'Record';

  @override
  String get albumGratitude => 'Thanks';

  @override
  String albumMemberTime(String name, int minutes) {
    return '$name • $minutes min';
  }

  @override
  String albumToday(String time) {
    return 'Today $time';
  }

  @override
  String albumYesterday(String time) {
    return 'Yesterday $time';
  }

  @override
  String albumDaysAgo(int days) {
    return '$days days ago';
  }

  @override
  String get recordListTitle => 'Record list';

  @override
  String get recordListLoginRequired => 'Login required';

  @override
  String get recordListNoRecords => 'No records';

  @override
  String recordListTotalMinutes(int minutes) {
    return '($minutes min)';
  }

  @override
  String get recordListTotalCost => 'Total cost';

  @override
  String get chartPast6Months => 'Past records (6 months)';

  @override
  String get chartBreakdown => 'Breakdown';

  @override
  String get chartNoData => 'No data yet';

  @override
  String get chartStartRecording => 'Start recording';

  @override
  String get chartInvitePartner => 'Invite your partner';

  @override
  String get chartInvitePartnerDesc => 'See your combined progress over time';

  @override
  String get chartNoDataYet => 'No data yet';

  @override
  String get chartKeepRecording => 'Keep recording to see your progress';

  @override
  String chartCountTimes(String name, int count) {
    return '$name\n$count times';
  }

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String errorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get operationFailed => 'Operation failed';

  @override
  String get addFailed => 'Failed to add';

  @override
  String get updateFailed => 'Failed to update';

  @override
  String get deleteFailed => 'Failed to delete';

  @override
  String get saveFailed => 'Failed to save';

  @override
  String get orderSaveFailed => 'Failed to save order';

  @override
  String get settingsNotificationDebug =>
      'Notification diagnostics for developers';

  @override
  String get settingsAuthProviderNotFound =>
      'Authentication provider not found';

  @override
  String get sender => 'Sender';

  @override
  String get categoryLoadFailed => 'Failed to load categories';

  @override
  String get now => 'Now';

  @override
  String get timeAgoJust => 'Just now';
}
