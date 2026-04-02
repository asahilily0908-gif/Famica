import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('ko'),
  ];

  /// No description provided for @appName.
  ///
  /// In ja, this message translates to:
  /// **'Famica'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In ja, this message translates to:
  /// **'ふたりのがんばりを10秒で記録'**
  String get appTagline;

  /// No description provided for @navRecord.
  ///
  /// In ja, this message translates to:
  /// **'記録'**
  String get navRecord;

  /// No description provided for @navCouple.
  ///
  /// In ja, this message translates to:
  /// **'ふたり'**
  String get navCouple;

  /// No description provided for @navLetter.
  ///
  /// In ja, this message translates to:
  /// **'手紙'**
  String get navLetter;

  /// No description provided for @navSettings.
  ///
  /// In ja, this message translates to:
  /// **'設定'**
  String get navSettings;

  /// No description provided for @you.
  ///
  /// In ja, this message translates to:
  /// **'あなた'**
  String get you;

  /// No description provided for @partner.
  ///
  /// In ja, this message translates to:
  /// **'パートナー'**
  String get partner;

  /// No description provided for @save.
  ///
  /// In ja, this message translates to:
  /// **'保存'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In ja, this message translates to:
  /// **'キャンセル'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In ja, this message translates to:
  /// **'削除'**
  String get delete;

  /// No description provided for @close.
  ///
  /// In ja, this message translates to:
  /// **'閉じる'**
  String get close;

  /// No description provided for @error.
  ///
  /// In ja, this message translates to:
  /// **'エラー'**
  String get error;

  /// No description provided for @loading.
  ///
  /// In ja, this message translates to:
  /// **'読み込み中...'**
  String get loading;

  /// No description provided for @logout.
  ///
  /// In ja, this message translates to:
  /// **'ログアウト'**
  String get logout;

  /// No description provided for @unset.
  ///
  /// In ja, this message translates to:
  /// **'未設定'**
  String get unset;

  /// No description provided for @uncategorized.
  ///
  /// In ja, this message translates to:
  /// **'未分類'**
  String get uncategorized;

  /// No description provided for @other.
  ///
  /// In ja, this message translates to:
  /// **'その他'**
  String get other;

  /// No description provided for @all.
  ///
  /// In ja, this message translates to:
  /// **'すべて'**
  String get all;

  /// No description provided for @send.
  ///
  /// In ja, this message translates to:
  /// **'送信'**
  String get send;

  /// No description provided for @copy.
  ///
  /// In ja, this message translates to:
  /// **'コピー'**
  String get copy;

  /// No description provided for @share.
  ///
  /// In ja, this message translates to:
  /// **'共有'**
  String get share;

  /// No description provided for @join.
  ///
  /// In ja, this message translates to:
  /// **'参加する'**
  String get join;

  /// No description provided for @members.
  ///
  /// In ja, this message translates to:
  /// **'メンバー'**
  String get members;

  /// No description provided for @today.
  ///
  /// In ja, this message translates to:
  /// **'今月'**
  String get today;

  /// No description provided for @task.
  ///
  /// In ja, this message translates to:
  /// **'タスク'**
  String get task;

  /// No description provided for @authEmailHint.
  ///
  /// In ja, this message translates to:
  /// **'example@mail.com'**
  String get authEmailHint;

  /// No description provided for @authEmailLabel.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレス'**
  String get authEmailLabel;

  /// No description provided for @authPasswordLabel.
  ///
  /// In ja, this message translates to:
  /// **'パスワード'**
  String get authPasswordLabel;

  /// No description provided for @authPasswordHint.
  ///
  /// In ja, this message translates to:
  /// **'6文字以上'**
  String get authPasswordHint;

  /// No description provided for @authNicknameLabel.
  ///
  /// In ja, this message translates to:
  /// **'ニックネーム'**
  String get authNicknameLabel;

  /// No description provided for @authNicknameHint.
  ///
  /// In ja, this message translates to:
  /// **'例：あさひ'**
  String get authNicknameHint;

  /// No description provided for @authNicknameHelper.
  ///
  /// In ja, this message translates to:
  /// **'アプリ内で表示される名前です'**
  String get authNicknameHelper;

  /// No description provided for @authHasInviteCode.
  ///
  /// In ja, this message translates to:
  /// **'招待コードを持っています'**
  String get authHasInviteCode;

  /// No description provided for @authInviteCodeLabel.
  ///
  /// In ja, this message translates to:
  /// **'招待コード'**
  String get authInviteCodeLabel;

  /// No description provided for @authInviteCodeHint.
  ///
  /// In ja, this message translates to:
  /// **'例：ABC123'**
  String get authInviteCodeHint;

  /// No description provided for @authInviteCodeHelper.
  ///
  /// In ja, this message translates to:
  /// **'パートナーから受け取ったコード'**
  String get authInviteCodeHelper;

  /// No description provided for @authHouseholdNameLabel.
  ///
  /// In ja, this message translates to:
  /// **'カップル名／世帯名'**
  String get authHouseholdNameLabel;

  /// No description provided for @authHouseholdNameHint.
  ///
  /// In ja, this message translates to:
  /// **'例：あさひ・りり'**
  String get authHouseholdNameHint;

  /// No description provided for @authHouseholdNameHelper.
  ///
  /// In ja, this message translates to:
  /// **'ふたりで共有するグループ名です'**
  String get authHouseholdNameHelper;

  /// No description provided for @authSignUp.
  ///
  /// In ja, this message translates to:
  /// **'新規登録'**
  String get authSignUp;

  /// No description provided for @authLoginOrSignUp.
  ///
  /// In ja, this message translates to:
  /// **'ログイン / 新規登録'**
  String get authLoginOrSignUp;

  /// No description provided for @authSwitchToLogin.
  ///
  /// In ja, this message translates to:
  /// **'既存アカウントでログイン'**
  String get authSwitchToLogin;

  /// No description provided for @authSignUpNote.
  ///
  /// In ja, this message translates to:
  /// **'※ ニックネームはアプリ内で表示されます'**
  String get authSignUpNote;

  /// No description provided for @authLoginNote.
  ///
  /// In ja, this message translates to:
  /// **'※ 既存ユーザーの場合はログイン、\n新規の場合は自動で登録されます'**
  String get authLoginNote;

  /// No description provided for @authErrorEmptyFields.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスとパスワードを入力してください'**
  String get authErrorEmptyFields;

  /// No description provided for @authErrorEmptyNickname.
  ///
  /// In ja, this message translates to:
  /// **'ニックネームを入力してください'**
  String get authErrorEmptyNickname;

  /// No description provided for @authErrorEmptyHousehold.
  ///
  /// In ja, this message translates to:
  /// **'カップル名を入力してください'**
  String get authErrorEmptyHousehold;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In ja, this message translates to:
  /// **'メールアドレスの形式が正しくありません'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードは6文字以上で入力してください'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorUserNotFound.
  ///
  /// In ja, this message translates to:
  /// **'アカウントが見つかりません。ニックネームを入力して新規登録してください'**
  String get authErrorUserNotFound;

  /// No description provided for @authErrorWrongPassword.
  ///
  /// In ja, this message translates to:
  /// **'パスワードが間違っています'**
  String get authErrorWrongPassword;

  /// No description provided for @authErrorDisabled.
  ///
  /// In ja, this message translates to:
  /// **'このアカウントは無効化されています'**
  String get authErrorDisabled;

  /// No description provided for @authErrorTooMany.
  ///
  /// In ja, this message translates to:
  /// **'リクエストが多すぎます。しばらく待ってから再度お試しください'**
  String get authErrorTooMany;

  /// No description provided for @authErrorNetwork.
  ///
  /// In ja, this message translates to:
  /// **'ネットワークエラーが発生しました'**
  String get authErrorNetwork;

  /// No description provided for @authErrorLogin.
  ///
  /// In ja, this message translates to:
  /// **'ログインエラー'**
  String get authErrorLogin;

  /// No description provided for @authErrorUnexpected.
  ///
  /// In ja, this message translates to:
  /// **'予期しないエラーが発生しました'**
  String get authErrorUnexpected;

  /// No description provided for @authErrorEmailInUse.
  ///
  /// In ja, this message translates to:
  /// **'このメールアドレスは既に使用されています'**
  String get authErrorEmailInUse;

  /// No description provided for @authErrorWeakPasswordSignUp.
  ///
  /// In ja, this message translates to:
  /// **'パスワードが弱すぎます。より強力なパスワードを設定してください'**
  String get authErrorWeakPasswordSignUp;

  /// No description provided for @authErrorOperationNotAllowed.
  ///
  /// In ja, this message translates to:
  /// **'メール/パスワード認証が有効になっていません'**
  String get authErrorOperationNotAllowed;

  /// No description provided for @authErrorSignUp.
  ///
  /// In ja, this message translates to:
  /// **'新規登録エラー'**
  String get authErrorSignUp;

  /// No description provided for @authLoginSuccess.
  ///
  /// In ja, this message translates to:
  /// **'ログインに成功しました'**
  String get authLoginSuccess;

  /// No description provided for @authSignUpSuccess.
  ///
  /// In ja, this message translates to:
  /// **'新規登録が完了しました！ようこそFamicaへ！'**
  String get authSignUpSuccess;

  /// No description provided for @authInviteSuccess.
  ///
  /// In ja, this message translates to:
  /// **'招待コード経由での登録が完了しました！'**
  String get authInviteSuccess;

  /// No description provided for @authInviteNotFound.
  ///
  /// In ja, this message translates to:
  /// **'招待コードが見つかりません'**
  String get authInviteNotFound;

  /// No description provided for @authInviteUsed.
  ///
  /// In ja, this message translates to:
  /// **'この招待コードは既に使用されています'**
  String get authInviteUsed;

  /// No description provided for @authErrorCreateUser.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーの作成に失敗しました'**
  String get authErrorCreateUser;

  /// No description provided for @authErrorHouseholdNotFound.
  ///
  /// In ja, this message translates to:
  /// **'世帯が見つかりません'**
  String get authErrorHouseholdNotFound;

  /// No description provided for @mainInitSetup.
  ///
  /// In ja, this message translates to:
  /// **'初期セットアップ中...'**
  String get mainInitSetup;

  /// No description provided for @mainCreatingUser.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報を作成しています'**
  String get mainCreatingUser;

  /// No description provided for @mainLoadingUser.
  ///
  /// In ja, this message translates to:
  /// **'ユーザー情報を読み込み中...'**
  String get mainLoadingUser;

  /// No description provided for @mainPreparingHousehold.
  ///
  /// In ja, this message translates to:
  /// **'世帯情報を準備中...'**
  String get mainPreparingHousehold;

  /// No description provided for @mainWaitingHousehold.
  ///
  /// In ja, this message translates to:
  /// **'householdIdの設定を待機しています'**
  String get mainWaitingHousehold;

  /// No description provided for @mainErrorOccurred.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました'**
  String get mainErrorOccurred;

  /// No description provided for @mainFirebaseError.
  ///
  /// In ja, this message translates to:
  /// **'Firebase初期化エラー'**
  String get mainFirebaseError;

  /// No description provided for @mainAuthError.
  ///
  /// In ja, this message translates to:
  /// **'認証エラー'**
  String get mainAuthError;

  /// No description provided for @quickRecord.
  ///
  /// In ja, this message translates to:
  /// **'クイック記録'**
  String get quickRecord;

  /// No description provided for @quickRecordPanelEdit.
  ///
  /// In ja, this message translates to:
  /// **'パネルの編集'**
  String get quickRecordPanelEdit;

  /// No description provided for @quickRecordTodayEffort.
  ///
  /// In ja, this message translates to:
  /// **'今日のがんばり'**
  String get quickRecordTodayEffort;

  /// No description provided for @quickRecordCountTimes.
  ///
  /// In ja, this message translates to:
  /// **'{count}回'**
  String quickRecordCountTimes(int count);

  /// No description provided for @quickRecordMinutes.
  ///
  /// In ja, this message translates to:
  /// **'{minutes}分'**
  String quickRecordMinutes(int minutes);

  /// No description provided for @quickRecordRecentRecords.
  ///
  /// In ja, this message translates to:
  /// **'最近の記録'**
  String get quickRecordRecentRecords;

  /// No description provided for @quickRecordSeeAll.
  ///
  /// In ja, this message translates to:
  /// **'すべて見る'**
  String get quickRecordSeeAll;

  /// No description provided for @quickRecordNoRecords.
  ///
  /// In ja, this message translates to:
  /// **'まだ記録がありません'**
  String get quickRecordNoRecords;

  /// No description provided for @quickRecordNoName.
  ///
  /// In ja, this message translates to:
  /// **'名無し'**
  String get quickRecordNoName;

  /// No description provided for @quickRecordAdded.
  ///
  /// In ja, this message translates to:
  /// **'✅ 記録を追加しました！'**
  String get quickRecordAdded;

  /// No description provided for @quickRecordThanks.
  ///
  /// In ja, this message translates to:
  /// **'💗 ありがとうを送りました'**
  String get quickRecordThanks;

  /// No description provided for @quickRecordCostRecord.
  ///
  /// In ja, this message translates to:
  /// **'コストを記録する'**
  String get quickRecordCostRecord;

  /// No description provided for @quickRecordSelectTime.
  ///
  /// In ja, this message translates to:
  /// **'時間を選択'**
  String get quickRecordSelectTime;

  /// No description provided for @quickRecordError.
  ///
  /// In ja, this message translates to:
  /// **'エラー: {error}'**
  String quickRecordError(String error);

  /// No description provided for @costRecordTitle.
  ///
  /// In ja, this message translates to:
  /// **'コストを記録'**
  String get costRecordTitle;

  /// No description provided for @costRecordAmount.
  ///
  /// In ja, this message translates to:
  /// **'金額'**
  String get costRecordAmount;

  /// No description provided for @costRecordAmountHint.
  ///
  /// In ja, this message translates to:
  /// **'1000'**
  String get costRecordAmountHint;

  /// No description provided for @costRecordPurpose.
  ///
  /// In ja, this message translates to:
  /// **'用途'**
  String get costRecordPurpose;

  /// No description provided for @costRecordPurposeHint.
  ///
  /// In ja, this message translates to:
  /// **'例：食材、日用品、交通費など'**
  String get costRecordPurposeHint;

  /// No description provided for @costRecordPayer.
  ///
  /// In ja, this message translates to:
  /// **'支払った人'**
  String get costRecordPayer;

  /// No description provided for @costRecordEmptyAmount.
  ///
  /// In ja, this message translates to:
  /// **'金額を入力してください'**
  String get costRecordEmptyAmount;

  /// No description provided for @costRecordInvalidAmount.
  ///
  /// In ja, this message translates to:
  /// **'正しい金額を入力してください'**
  String get costRecordInvalidAmount;

  /// No description provided for @costRecordSuccess.
  ///
  /// In ja, this message translates to:
  /// **'💰 コストを記録しました'**
  String get costRecordSuccess;

  /// No description provided for @costRecordFailed.
  ///
  /// In ja, this message translates to:
  /// **'保存に失敗しました'**
  String get costRecordFailed;

  /// No description provided for @costRecordNoPurpose.
  ///
  /// In ja, this message translates to:
  /// **'用途未記入'**
  String get costRecordNoPurpose;

  /// No description provided for @coupleActionTip.
  ///
  /// In ja, this message translates to:
  /// **'行動のヒント'**
  String get coupleActionTip;

  /// No description provided for @coupleThisMonth.
  ///
  /// In ja, this message translates to:
  /// **'今月'**
  String get coupleThisMonth;

  /// No description provided for @coupleSendGratitude.
  ///
  /// In ja, this message translates to:
  /// **'感謝メッセージを送る'**
  String get coupleSendGratitude;

  /// No description provided for @coupleSendGratitudeDesc.
  ///
  /// In ja, this message translates to:
  /// **'パートナーに感謝の気持ちを伝えましょう'**
  String get coupleSendGratitudeDesc;

  /// No description provided for @coupleGratitudeReceived.
  ///
  /// In ja, this message translates to:
  /// **'感謝カードが届いています'**
  String get coupleGratitudeReceived;

  /// No description provided for @coupleTapToRead.
  ///
  /// In ja, this message translates to:
  /// **'タップして読む'**
  String get coupleTapToRead;

  /// No description provided for @coupleMonthlyBreakdown.
  ///
  /// In ja, this message translates to:
  /// **'今月の家事内訳（カテゴリ別の合計）'**
  String get coupleMonthlyBreakdown;

  /// No description provided for @coupleMonthlyCost.
  ///
  /// In ja, this message translates to:
  /// **'今月のコスト（支出）'**
  String get coupleMonthlyCost;

  /// No description provided for @coupleTotal.
  ///
  /// In ja, this message translates to:
  /// **'合計'**
  String get coupleTotal;

  /// No description provided for @coupleNoSuggestion.
  ///
  /// In ja, this message translates to:
  /// **'今月の提案はまだありません💡'**
  String get coupleNoSuggestion;

  /// No description provided for @coupleSuggestion.
  ///
  /// In ja, this message translates to:
  /// **'提案'**
  String get coupleSuggestion;

  /// No description provided for @coupleSuggestionOverworked.
  ///
  /// In ja, this message translates to:
  /// **'あなたに少し負担が偏っているようです。\nたまにはパートナーに任せてリラックスしてもいいかも☺️'**
  String get coupleSuggestionOverworked;

  /// No description provided for @coupleSuggestionPartnerOverworked.
  ///
  /// In ja, this message translates to:
  /// **'パートナーに少し負担が偏っているようです。\n感謝の気持ちを伝えてみましょう💕'**
  String get coupleSuggestionPartnerOverworked;

  /// No description provided for @coupleSuggestionBalanced.
  ///
  /// In ja, this message translates to:
  /// **'料理のバランスが良いですね！\nこの調子で続けていきましょう✨'**
  String get coupleSuggestionBalanced;

  /// No description provided for @couplePartnerNotFound.
  ///
  /// In ja, this message translates to:
  /// **'パートナーが見つかりません'**
  String get couplePartnerNotFound;

  /// No description provided for @coupleSendGratitudeCard.
  ///
  /// In ja, this message translates to:
  /// **'感謝カードを送る'**
  String get coupleSendGratitudeCard;

  /// No description provided for @coupleSendTo.
  ///
  /// In ja, this message translates to:
  /// **'送り先：'**
  String get coupleSendTo;

  /// No description provided for @coupleMessage.
  ///
  /// In ja, this message translates to:
  /// **'メッセージ'**
  String get coupleMessage;

  /// No description provided for @coupleMessageHint.
  ///
  /// In ja, this message translates to:
  /// **'例：いつも洗い物してくれてありがとう😊'**
  String get coupleMessageHint;

  /// No description provided for @coupleEmptyMessage.
  ///
  /// In ja, this message translates to:
  /// **'メッセージを入力してください'**
  String get coupleEmptyMessage;

  /// No description provided for @coupleSendFailed.
  ///
  /// In ja, this message translates to:
  /// **'送信に失敗しました'**
  String get coupleSendFailed;

  /// No description provided for @letterTitle.
  ///
  /// In ja, this message translates to:
  /// **'パートナーからの感謝メッセージ'**
  String get letterTitle;

  /// No description provided for @letterPleaseLogin.
  ///
  /// In ja, this message translates to:
  /// **'ログインしてください'**
  String get letterPleaseLogin;

  /// No description provided for @letterNoMessages.
  ///
  /// In ja, this message translates to:
  /// **'まだ感謝メッセージは届いていません'**
  String get letterNoMessages;

  /// No description provided for @letterUnread.
  ///
  /// In ja, this message translates to:
  /// **'未読'**
  String get letterUnread;

  /// No description provided for @letterFromUser.
  ///
  /// In ja, this message translates to:
  /// **'{name}さんから'**
  String letterFromUser(String name);

  /// No description provided for @settingsInvitePartner.
  ///
  /// In ja, this message translates to:
  /// **'パートナーを招待'**
  String get settingsInvitePartner;

  /// No description provided for @settingsChangeNickname.
  ///
  /// In ja, this message translates to:
  /// **'ニックネーム変更'**
  String get settingsChangeNickname;

  /// No description provided for @settingsPrivacyPolicy.
  ///
  /// In ja, this message translates to:
  /// **'プライバシーポリシー'**
  String get settingsPrivacyPolicy;

  /// No description provided for @settingsHelp.
  ///
  /// In ja, this message translates to:
  /// **'ヘルプ・お問い合わせ'**
  String get settingsHelp;

  /// No description provided for @settingsTerms.
  ///
  /// In ja, this message translates to:
  /// **'利用規約'**
  String get settingsTerms;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In ja, this message translates to:
  /// **'アカウント削除'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteConfirm.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除しますか？'**
  String get settingsDeleteConfirm;

  /// No description provided for @settingsDeleteWarning.
  ///
  /// In ja, this message translates to:
  /// **'削除すると、以下の情報が完全に削除されます'**
  String get settingsDeleteWarning;

  /// No description provided for @settingsDeleteRecords.
  ///
  /// In ja, this message translates to:
  /// **'• すべての記録データ'**
  String get settingsDeleteRecords;

  /// No description provided for @settingsDeletePartner.
  ///
  /// In ja, this message translates to:
  /// **'• パートナー共有情報'**
  String get settingsDeletePartner;

  /// No description provided for @settingsDeleteIrreversible.
  ///
  /// In ja, this message translates to:
  /// **'この操作は元に戻せません'**
  String get settingsDeleteIrreversible;

  /// No description provided for @settingsDeleteButton.
  ///
  /// In ja, this message translates to:
  /// **'削除する'**
  String get settingsDeleteButton;

  /// No description provided for @settingsDeleting.
  ///
  /// In ja, this message translates to:
  /// **'アカウントを削除しています...'**
  String get settingsDeleting;

  /// No description provided for @settingsDeleteUserNotFound.
  ///
  /// In ja, this message translates to:
  /// **'ユーザーが見つかりません'**
  String get settingsDeleteUserNotFound;

  /// No description provided for @settingsDeleteFirestoreFailed.
  ///
  /// In ja, this message translates to:
  /// **'Firestoreデータの削除に失敗しました'**
  String get settingsDeleteFirestoreFailed;

  /// No description provided for @settingsDeleteFailed.
  ///
  /// In ja, this message translates to:
  /// **'削除に失敗しました'**
  String get settingsDeleteFailed;

  /// No description provided for @settingsReauthRequired.
  ///
  /// In ja, this message translates to:
  /// **'再認証が必要です'**
  String get settingsReauthRequired;

  /// No description provided for @settingsReauthFailed.
  ///
  /// In ja, this message translates to:
  /// **'再認証に失敗しました'**
  String get settingsReauthFailed;

  /// No description provided for @settingsReauthError.
  ///
  /// In ja, this message translates to:
  /// **'再認証中にエラーが発生しました'**
  String get settingsReauthError;

  /// No description provided for @settingsReauthInstruction.
  ///
  /// In ja, this message translates to:
  /// **'メール/パスワードでログインしている場合は、\n一度ログアウトして再ログイン後に\nアカウント削除を実行してください。'**
  String get settingsReauthInstruction;

  /// No description provided for @settingsUnsupportedAuth.
  ///
  /// In ja, this message translates to:
  /// **'サポートされていない認証方法です'**
  String get settingsUnsupportedAuth;

  /// No description provided for @settingsLogoutConfirm.
  ///
  /// In ja, this message translates to:
  /// **'ログアウトしますか？\n再度ログインが必要になります。'**
  String get settingsLogoutConfirm;

  /// No description provided for @settingsLogoutButton.
  ///
  /// In ja, this message translates to:
  /// **'ログアウトする'**
  String get settingsLogoutButton;

  /// No description provided for @settingsNicknameChange.
  ///
  /// In ja, this message translates to:
  /// **'ニックネーム変更'**
  String get settingsNicknameChange;

  /// No description provided for @settingsNicknameInput.
  ///
  /// In ja, this message translates to:
  /// **'ニックネームを入力'**
  String get settingsNicknameInput;

  /// No description provided for @settingsNicknameEmpty.
  ///
  /// In ja, this message translates to:
  /// **'ニックネームを入力してください'**
  String get settingsNicknameEmpty;

  /// No description provided for @settingsNicknameSaved.
  ///
  /// In ja, this message translates to:
  /// **'✅ 変更を保存しました'**
  String get settingsNicknameSaved;

  /// No description provided for @settingsNicknameError.
  ///
  /// In ja, this message translates to:
  /// **'❌ エラーが発生しました'**
  String get settingsNicknameError;

  /// No description provided for @settingsNicknameNote.
  ///
  /// In ja, this message translates to:
  /// **'ℹ️ ニックネームは全画面で即時反映されます'**
  String get settingsNicknameNote;

  /// No description provided for @settingsSaveChanges.
  ///
  /// In ja, this message translates to:
  /// **'変更を保存'**
  String get settingsSaveChanges;

  /// No description provided for @inviteTitle.
  ///
  /// In ja, this message translates to:
  /// **'パートナーを招待'**
  String get inviteTitle;

  /// No description provided for @inviteDescription.
  ///
  /// In ja, this message translates to:
  /// **'パートナーをFamicaに招待しましょう！'**
  String get inviteDescription;

  /// No description provided for @inviteYourCode.
  ///
  /// In ja, this message translates to:
  /// **'あなたの招待コード'**
  String get inviteYourCode;

  /// No description provided for @inviteCopied.
  ///
  /// In ja, this message translates to:
  /// **'招待コードをコピーしました'**
  String get inviteCopied;

  /// No description provided for @inviteShareSubject.
  ///
  /// In ja, this message translates to:
  /// **'Famicaに招待します'**
  String get inviteShareSubject;

  /// No description provided for @inviteEnterCode.
  ///
  /// In ja, this message translates to:
  /// **'招待コードを入力'**
  String get inviteEnterCode;

  /// No description provided for @inviteEnterCodeDesc.
  ///
  /// In ja, this message translates to:
  /// **'パートナーから受け取った\n6桁のコードを入力してください'**
  String get inviteEnterCodeDesc;

  /// No description provided for @inviteCodeHint.
  ///
  /// In ja, this message translates to:
  /// **'ABC123'**
  String get inviteCodeHint;

  /// No description provided for @inviteEmptyCode.
  ///
  /// In ja, this message translates to:
  /// **'招待コードを入力してください'**
  String get inviteEmptyCode;

  /// No description provided for @inviteInvalidCode.
  ///
  /// In ja, this message translates to:
  /// **'招待コードが無効です'**
  String get inviteInvalidCode;

  /// No description provided for @inviteJoinSuccess.
  ///
  /// In ja, this message translates to:
  /// **'✅ 参加しました！'**
  String get inviteJoinSuccess;

  /// No description provided for @inviteJoinFailed.
  ///
  /// In ja, this message translates to:
  /// **'参加に失敗しました'**
  String get inviteJoinFailed;

  /// No description provided for @inviteNoMembers.
  ///
  /// In ja, this message translates to:
  /// **'まだメンバーがいません'**
  String get inviteNoMembers;

  /// No description provided for @inviteNoPartner.
  ///
  /// In ja, this message translates to:
  /// **'まだパートナーがいません'**
  String get inviteNoPartner;

  /// No description provided for @inviteNoPartnerDesc.
  ///
  /// In ja, this message translates to:
  /// **'パートナーから招待コードを\n受け取って参加しましょう'**
  String get inviteNoPartnerDesc;

  /// No description provided for @invitePartnerCardTitle.
  ///
  /// In ja, this message translates to:
  /// **'パートナーを招待して、\nふたりの記録を見える化しよう'**
  String get invitePartnerCardTitle;

  /// No description provided for @invitePartnerCardDesc.
  ///
  /// In ja, this message translates to:
  /// **'招待リンクを送るだけで、共有が始まります'**
  String get invitePartnerCardDesc;

  /// No description provided for @invitePartnerCardButton.
  ///
  /// In ja, this message translates to:
  /// **'招待リンクを共有'**
  String get invitePartnerCardButton;

  /// No description provided for @categoryEditTitle.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリを編集'**
  String get categoryEditTitle;

  /// No description provided for @categoryAddTitle.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリを追加'**
  String get categoryAddTitle;

  /// No description provided for @categoryEmpty.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリがありません'**
  String get categoryEmpty;

  /// No description provided for @categoryEmptyHint.
  ///
  /// In ja, this message translates to:
  /// **'＋ボタンでカテゴリを追加しましょう'**
  String get categoryEmptyHint;

  /// No description provided for @categoryMaxReached.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリは最大12件までです'**
  String get categoryMaxReached;

  /// No description provided for @categoryAdded.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリを追加しました'**
  String get categoryAdded;

  /// No description provided for @categoryUpdated.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリを更新しました'**
  String get categoryUpdated;

  /// No description provided for @categoryDeleteConfirm.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリを削除しますか？'**
  String get categoryDeleteConfirm;

  /// No description provided for @categoryDeleteNote.
  ///
  /// In ja, this message translates to:
  /// **'このカテゴリに紐づく記録は残ります。'**
  String get categoryDeleteNote;

  /// No description provided for @categoryDeleted.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリを削除しました'**
  String get categoryDeleted;

  /// No description provided for @categoryStandardNote.
  ///
  /// In ja, this message translates to:
  /// **'※ このカテゴリは標準カテゴリのため削除できません'**
  String get categoryStandardNote;

  /// No description provided for @categoryOrderSaved.
  ///
  /// In ja, this message translates to:
  /// **'並び順を保存しました'**
  String get categoryOrderSaved;

  /// No description provided for @categoryEmoji.
  ///
  /// In ja, this message translates to:
  /// **'絵文字'**
  String get categoryEmoji;

  /// No description provided for @categorySelectEmoji.
  ///
  /// In ja, this message translates to:
  /// **'タップしてアイコンを選ぶ'**
  String get categorySelectEmoji;

  /// No description provided for @categorySelectEmojiTitle.
  ///
  /// In ja, this message translates to:
  /// **'アイコンを選択'**
  String get categorySelectEmojiTitle;

  /// No description provided for @categoryName.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリ名'**
  String get categoryName;

  /// No description provided for @categoryNameHint.
  ///
  /// In ja, this message translates to:
  /// **'例：お弁当作り'**
  String get categoryNameHint;

  /// No description provided for @categoryDuration.
  ///
  /// In ja, this message translates to:
  /// **'所要時間（分）'**
  String get categoryDuration;

  /// No description provided for @categorySelectDuration.
  ///
  /// In ja, this message translates to:
  /// **'所要時間を選択'**
  String get categorySelectDuration;

  /// No description provided for @categoryNameEmpty.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリ名を入力してください'**
  String get categoryNameEmpty;

  /// No description provided for @categoryEmojiEmpty.
  ///
  /// In ja, this message translates to:
  /// **'絵文字を選択してください'**
  String get categoryEmojiEmpty;

  /// No description provided for @categoryInvalidTime.
  ///
  /// In ja, this message translates to:
  /// **'正しい時間を入力してください'**
  String get categoryInvalidTime;

  /// No description provided for @gratitudeHistoryTitle.
  ///
  /// In ja, this message translates to:
  /// **'📮 貰った感謝一覧'**
  String get gratitudeHistoryTitle;

  /// No description provided for @gratitudeEmpty.
  ///
  /// In ja, this message translates to:
  /// **'感謝カードはまだありません'**
  String get gratitudeEmpty;

  /// No description provided for @gratitudeSender.
  ///
  /// In ja, this message translates to:
  /// **'送信者'**
  String get gratitudeSender;

  /// No description provided for @nicknameChangeTitle.
  ///
  /// In ja, this message translates to:
  /// **'ニックネーム変更'**
  String get nicknameChangeTitle;

  /// No description provided for @nicknameLabel.
  ///
  /// In ja, this message translates to:
  /// **'ニックネーム'**
  String get nicknameLabel;

  /// No description provided for @nicknameInputHint.
  ///
  /// In ja, this message translates to:
  /// **'ニックネームを入力'**
  String get nicknameInputHint;

  /// No description provided for @nicknameEmpty.
  ///
  /// In ja, this message translates to:
  /// **'ニックネームを入力してください'**
  String get nicknameEmpty;

  /// No description provided for @nicknameSaved.
  ///
  /// In ja, this message translates to:
  /// **'✅ 変更を保存しました'**
  String get nicknameSaved;

  /// No description provided for @nicknameNote.
  ///
  /// In ja, this message translates to:
  /// **'ℹ️ ニックネームは全画面で即時反映されます'**
  String get nicknameNote;

  /// No description provided for @albumTitle.
  ///
  /// In ja, this message translates to:
  /// **'アルバム'**
  String get albumTitle;

  /// No description provided for @albumOurAlbum.
  ///
  /// In ja, this message translates to:
  /// **'ふたりのアルバム'**
  String get albumOurAlbum;

  /// No description provided for @albumRecordsOnly.
  ///
  /// In ja, this message translates to:
  /// **'記録のみ'**
  String get albumRecordsOnly;

  /// No description provided for @albumGratitudeOnly.
  ///
  /// In ja, this message translates to:
  /// **'感謝のみ'**
  String get albumGratitudeOnly;

  /// No description provided for @albumNoItems.
  ///
  /// In ja, this message translates to:
  /// **'まだアルバムがありません'**
  String get albumNoItems;

  /// No description provided for @albumNoItemsDesc.
  ///
  /// In ja, this message translates to:
  /// **'記録や感謝が\nアルバムに表示されます'**
  String get albumNoItemsDesc;

  /// No description provided for @albumRecord.
  ///
  /// In ja, this message translates to:
  /// **'記録'**
  String get albumRecord;

  /// No description provided for @albumGratitude.
  ///
  /// In ja, this message translates to:
  /// **'感謝'**
  String get albumGratitude;

  /// No description provided for @albumMemberTime.
  ///
  /// In ja, this message translates to:
  /// **'{name} • {minutes}分'**
  String albumMemberTime(String name, int minutes);

  /// No description provided for @albumToday.
  ///
  /// In ja, this message translates to:
  /// **'今日 {time}'**
  String albumToday(String time);

  /// No description provided for @albumYesterday.
  ///
  /// In ja, this message translates to:
  /// **'昨日 {time}'**
  String albumYesterday(String time);

  /// No description provided for @albumDaysAgo.
  ///
  /// In ja, this message translates to:
  /// **'{days}日前'**
  String albumDaysAgo(int days);

  /// No description provided for @recordListTitle.
  ///
  /// In ja, this message translates to:
  /// **'記録一覧'**
  String get recordListTitle;

  /// No description provided for @recordListLoginRequired.
  ///
  /// In ja, this message translates to:
  /// **'ログインが必要です'**
  String get recordListLoginRequired;

  /// No description provided for @recordListNoRecords.
  ///
  /// In ja, this message translates to:
  /// **'記録がありません'**
  String get recordListNoRecords;

  /// No description provided for @recordListTotalMinutes.
  ///
  /// In ja, this message translates to:
  /// **'({minutes}分)'**
  String recordListTotalMinutes(int minutes);

  /// No description provided for @recordListTotalCost.
  ///
  /// In ja, this message translates to:
  /// **'総コスト'**
  String get recordListTotalCost;

  /// No description provided for @chartPast6Months.
  ///
  /// In ja, this message translates to:
  /// **'過去記録（6ヶ月分）'**
  String get chartPast6Months;

  /// No description provided for @chartBreakdown.
  ///
  /// In ja, this message translates to:
  /// **'内訳'**
  String get chartBreakdown;

  /// No description provided for @chartNoData.
  ///
  /// In ja, this message translates to:
  /// **'まだデータがありません'**
  String get chartNoData;

  /// No description provided for @chartStartRecording.
  ///
  /// In ja, this message translates to:
  /// **'記録をしてみましょう'**
  String get chartStartRecording;

  /// No description provided for @chartInvitePartner.
  ///
  /// In ja, this message translates to:
  /// **'パートナーを招待しよう'**
  String get chartInvitePartner;

  /// No description provided for @chartInvitePartnerDesc.
  ///
  /// In ja, this message translates to:
  /// **'ふたりの推移を確認できるようになります'**
  String get chartInvitePartnerDesc;

  /// No description provided for @chartNoDataYet.
  ///
  /// In ja, this message translates to:
  /// **'まだデータがありません 😌'**
  String get chartNoDataYet;

  /// No description provided for @chartKeepRecording.
  ///
  /// In ja, this message translates to:
  /// **'記録を続けて推移を確認しましょう'**
  String get chartKeepRecording;

  /// No description provided for @chartCountTimes.
  ///
  /// In ja, this message translates to:
  /// **'{name}\n{count}回'**
  String chartCountTimes(String name, int count);

  /// No description provided for @errorOccurred.
  ///
  /// In ja, this message translates to:
  /// **'エラーが発生しました'**
  String get errorOccurred;

  /// No description provided for @errorWithMessage.
  ///
  /// In ja, this message translates to:
  /// **'エラー: {message}'**
  String errorWithMessage(String message);

  /// No description provided for @operationFailed.
  ///
  /// In ja, this message translates to:
  /// **'操作に失敗しました'**
  String get operationFailed;

  /// No description provided for @addFailed.
  ///
  /// In ja, this message translates to:
  /// **'追加に失敗しました'**
  String get addFailed;

  /// No description provided for @updateFailed.
  ///
  /// In ja, this message translates to:
  /// **'更新に失敗しました'**
  String get updateFailed;

  /// No description provided for @deleteFailed.
  ///
  /// In ja, this message translates to:
  /// **'削除に失敗しました'**
  String get deleteFailed;

  /// No description provided for @saveFailed.
  ///
  /// In ja, this message translates to:
  /// **'保存に失敗しました'**
  String get saveFailed;

  /// No description provided for @orderSaveFailed.
  ///
  /// In ja, this message translates to:
  /// **'並び順の保存に失敗しました'**
  String get orderSaveFailed;

  /// No description provided for @settingsNotificationDebug.
  ///
  /// In ja, this message translates to:
  /// **'開発者向け通知診断'**
  String get settingsNotificationDebug;

  /// No description provided for @settingsAuthProviderNotFound.
  ///
  /// In ja, this message translates to:
  /// **'認証プロバイダーが見つかりません'**
  String get settingsAuthProviderNotFound;

  /// No description provided for @sender.
  ///
  /// In ja, this message translates to:
  /// **'送信者'**
  String get sender;

  /// No description provided for @categoryLoadFailed.
  ///
  /// In ja, this message translates to:
  /// **'カテゴリの読み込みに失敗しました'**
  String get categoryLoadFailed;

  /// No description provided for @now.
  ///
  /// In ja, this message translates to:
  /// **'今'**
  String get now;

  /// No description provided for @timeAgoJust.
  ///
  /// In ja, this message translates to:
  /// **'たった今'**
  String get timeAgoJust;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ja', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ja':
      return AppLocalizationsJa();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
