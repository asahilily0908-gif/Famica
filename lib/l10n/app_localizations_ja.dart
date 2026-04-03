// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appName => 'Famica';

  @override
  String get appTagline => 'ふたりのがんばりを10秒で記録';

  @override
  String get navRecord => '記録';

  @override
  String get navCouple => 'ふたり';

  @override
  String get navLetter => '手紙';

  @override
  String get navSettings => '設定';

  @override
  String get you => 'あなた';

  @override
  String get partner => 'パートナー';

  @override
  String get save => '保存';

  @override
  String get cancel => 'キャンセル';

  @override
  String get delete => '削除';

  @override
  String get close => '閉じる';

  @override
  String get error => 'エラー';

  @override
  String get loading => '読み込み中...';

  @override
  String get logout => 'ログアウト';

  @override
  String get unset => '未設定';

  @override
  String get uncategorized => '未分類';

  @override
  String get other => 'その他';

  @override
  String get all => 'すべて';

  @override
  String get send => '送信';

  @override
  String get copy => 'コピー';

  @override
  String get share => '共有';

  @override
  String get join => '参加する';

  @override
  String get members => 'メンバー';

  @override
  String get today => '今月';

  @override
  String get task => 'タスク';

  @override
  String get authEmailHint => 'example@mail.com';

  @override
  String get authEmailLabel => 'メールアドレス';

  @override
  String get authPasswordLabel => 'パスワード';

  @override
  String get authPasswordHint => '6文字以上';

  @override
  String get authNicknameLabel => 'ニックネーム';

  @override
  String get authNicknameHint => '例：あさひ';

  @override
  String get authNicknameHelper => 'アプリ内で表示される名前です';

  @override
  String get authHasInviteCode => '招待コードを持っています';

  @override
  String get authInviteCodeLabel => '招待コード';

  @override
  String get authInviteCodeHint => '例：ABC123';

  @override
  String get authInviteCodeHelper => 'パートナーから受け取ったコード';

  @override
  String get authHouseholdNameLabel => 'カップル名／世帯名';

  @override
  String get authHouseholdNameHint => '例：あさひ・りり';

  @override
  String get authHouseholdNameHelper => 'ふたりで共有するグループ名です';

  @override
  String get authSignUp => '新規登録';

  @override
  String get authLoginOrSignUp => 'ログイン / 新規登録';

  @override
  String get authSwitchToLogin => '既存アカウントでログイン';

  @override
  String get authSignUpNote => '※ ニックネームはアプリ内で表示されます';

  @override
  String get authLoginNote => '※ 既存ユーザーの場合はログイン、\n新規の場合は自動で登録されます';

  @override
  String get authErrorEmptyFields => 'メールアドレスとパスワードを入力してください';

  @override
  String get authErrorEmptyNickname => 'ニックネームを入力してください';

  @override
  String get authErrorEmptyHousehold => 'カップル名を入力してください';

  @override
  String get authErrorInvalidEmail => 'メールアドレスの形式が正しくありません';

  @override
  String get authErrorWeakPassword => 'パスワードは6文字以上で入力してください';

  @override
  String get authErrorUserNotFound => 'アカウントが見つかりません。ニックネームを入力して新規登録してください';

  @override
  String get authErrorWrongPassword => 'パスワードが間違っています';

  @override
  String get authErrorDisabled => 'このアカウントは無効化されています';

  @override
  String get authErrorTooMany => 'リクエストが多すぎます。しばらく待ってから再度お試しください';

  @override
  String get authErrorNetwork => 'ネットワークエラーが発生しました';

  @override
  String get authErrorLogin => 'ログインエラー';

  @override
  String get authErrorUnexpected => '予期しないエラーが発生しました';

  @override
  String get authErrorEmailInUse => 'このメールアドレスは既に使用されています';

  @override
  String get authErrorWeakPasswordSignUp => 'パスワードが弱すぎます。より強力なパスワードを設定してください';

  @override
  String get authErrorOperationNotAllowed => 'メール/パスワード認証が有効になっていません';

  @override
  String get authErrorSignUp => '新規登録エラー';

  @override
  String get authLoginSuccess => 'ログインに成功しました';

  @override
  String get authSignUpSuccess => '新規登録が完了しました！ようこそFamicaへ！';

  @override
  String get authInviteSuccess => '招待コード経由での登録が完了しました！';

  @override
  String get authInviteNotFound => '招待コードが見つかりません';

  @override
  String get authInviteUsed => 'この招待コードは既に使用されています';

  @override
  String get authErrorCreateUser => 'ユーザーの作成に失敗しました';

  @override
  String get authErrorHouseholdNotFound => '世帯が見つかりません';

  @override
  String get mainInitSetup => '初期セットアップ中...';

  @override
  String get mainCreatingUser => 'ユーザー情報を作成しています';

  @override
  String get mainLoadingUser => 'ユーザー情報を読み込み中...';

  @override
  String get mainPreparingHousehold => '世帯情報を準備中...';

  @override
  String get mainWaitingHousehold => 'householdIdの設定を待機しています';

  @override
  String get mainErrorOccurred => 'エラーが発生しました';

  @override
  String get mainFirebaseError => 'Firebase初期化エラー';

  @override
  String get mainAuthError => '認証エラー';

  @override
  String get quickRecord => 'クイック記録';

  @override
  String get quickRecordPanelEdit => 'パネルの編集';

  @override
  String get quickRecordTodayEffort => '今日のがんばり';

  @override
  String quickRecordCountTimes(int count) {
    return '$count回';
  }

  @override
  String quickRecordMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get quickRecordRecentRecords => '最近の記録';

  @override
  String get quickRecordSeeAll => 'すべて見る';

  @override
  String get quickRecordNoRecords => 'まだ記録がありません';

  @override
  String get quickRecordNoName => '名無し';

  @override
  String get quickRecordAdded => '✅ 記録を追加しました！';

  @override
  String get quickRecordThanks => '💗 ありがとうを送りました';

  @override
  String get quickRecordCostRecord => 'コストを記録する';

  @override
  String get quickRecordSelectTime => '時間を選択';

  @override
  String quickRecordError(String error) {
    return 'エラー: $error';
  }

  @override
  String get costRecordTitle => 'コストを記録';

  @override
  String get costRecordAmount => '金額';

  @override
  String get costRecordAmountHint => '1000';

  @override
  String get costRecordPurpose => '用途';

  @override
  String get costRecordPurposeHint => '例：食材、日用品、交通費など';

  @override
  String get costRecordPayer => '支払った人';

  @override
  String get costRecordEmptyAmount => '金額を入力してください';

  @override
  String get costRecordInvalidAmount => '正しい金額を入力してください';

  @override
  String get costRecordSuccess => '💰 コストを記録しました';

  @override
  String get costRecordFailed => '保存に失敗しました';

  @override
  String get costRecordNoPurpose => '用途未記入';

  @override
  String get coupleActionTip => '行動のヒント';

  @override
  String get coupleThisMonth => '今月';

  @override
  String get coupleSendGratitude => '感謝メッセージを送る';

  @override
  String get coupleSendGratitudeDesc => 'パートナーに感謝の気持ちを伝えましょう';

  @override
  String get coupleGratitudeReceived => '感謝カードが届いています';

  @override
  String get coupleTapToRead => 'タップして読む';

  @override
  String get coupleMonthlyBreakdown => '今月の家事内訳（カテゴリ別の合計）';

  @override
  String get coupleMonthlyCost => '今月のコスト（支出）';

  @override
  String get coupleTotal => '合計';

  @override
  String get coupleNoSuggestion => '今月の提案はまだありません💡';

  @override
  String get coupleSuggestion => '提案';

  @override
  String get coupleSuggestionOverworked =>
      'あなたに少し負担が偏っているようです。\nたまにはパートナーに任せてリラックスしてもいいかも☺️';

  @override
  String get coupleSuggestionPartnerOverworked =>
      'パートナーに少し負担が偏っているようです。\n感謝の気持ちを伝えてみましょう💕';

  @override
  String get coupleSuggestionBalanced => '料理のバランスが良いですね！\nこの調子で続けていきましょう✨';

  @override
  String get couplePartnerNotFound => 'パートナーが見つかりません';

  @override
  String get coupleSendGratitudeCard => '感謝カードを送る';

  @override
  String get coupleSendTo => '送り先：';

  @override
  String get coupleMessage => 'メッセージ';

  @override
  String get coupleMessageHint => '例：いつも洗い物してくれてありがとう😊';

  @override
  String get coupleEmptyMessage => 'メッセージを入力してください';

  @override
  String get coupleSendFailed => '送信に失敗しました';

  @override
  String get letterTitle => 'パートナーからの感謝メッセージ';

  @override
  String get letterPleaseLogin => 'ログインしてください';

  @override
  String get letterNoMessages => 'まだ感謝メッセージは届いていません';

  @override
  String get letterUnread => '未読';

  @override
  String letterFromUser(String name) {
    return '$nameさんから';
  }

  @override
  String get settingsInvitePartner => 'パートナーを招待';

  @override
  String get settingsChangeNickname => 'ニックネーム変更';

  @override
  String get settingsPrivacyPolicy => 'プライバシーポリシー';

  @override
  String get settingsHelp => 'ヘルプ・お問い合わせ';

  @override
  String get settingsTerms => '利用規約';

  @override
  String get settingsDeleteAccount => 'アカウント削除';

  @override
  String get settingsDeleteConfirm => 'アカウントを削除しますか？';

  @override
  String get settingsDeleteWarning => '削除すると、以下の情報が完全に削除されます';

  @override
  String get settingsDeleteRecords => '• すべての記録データ';

  @override
  String get settingsDeletePartner => '• パートナー共有情報';

  @override
  String get settingsDeleteIrreversible => 'この操作は元に戻せません';

  @override
  String get settingsDeleteButton => '削除する';

  @override
  String get settingsDeleting => 'アカウントを削除しています...';

  @override
  String get settingsDeleteUserNotFound => 'ユーザーが見つかりません';

  @override
  String get settingsDeleteFirestoreFailed => 'Firestoreデータの削除に失敗しました';

  @override
  String get settingsDeleteFailed => '削除に失敗しました';

  @override
  String get settingsReauthRequired => '再認証が必要です';

  @override
  String get settingsReauthFailed => '再認証に失敗しました';

  @override
  String get settingsReauthError => '再認証中にエラーが発生しました';

  @override
  String get settingsReauthInstruction =>
      'メール/パスワードでログインしている場合は、\n一度ログアウトして再ログイン後に\nアカウント削除を実行してください。';

  @override
  String get settingsUnsupportedAuth => 'サポートされていない認証方法です';

  @override
  String get settingsLogoutConfirm => 'ログアウトしますか？\n再度ログインが必要になります。';

  @override
  String get settingsLogoutButton => 'ログアウトする';

  @override
  String get settingsNicknameChange => 'ニックネーム変更';

  @override
  String get settingsNicknameInput => 'ニックネームを入力';

  @override
  String get settingsNicknameEmpty => 'ニックネームを入力してください';

  @override
  String get settingsNicknameSaved => '✅ 変更を保存しました';

  @override
  String get settingsNicknameError => '❌ エラーが発生しました';

  @override
  String get settingsNicknameNote => 'ℹ️ ニックネームは全画面で即時反映されます';

  @override
  String get settingsSaveChanges => '変更を保存';

  @override
  String get inviteTitle => 'パートナーを招待';

  @override
  String get inviteDescription => 'パートナーをFamicaに招待しましょう！';

  @override
  String get inviteYourCode => 'あなたの招待コード';

  @override
  String get inviteCopied => '招待コードをコピーしました';

  @override
  String get inviteShareSubject => 'Famicaに招待します';

  @override
  String get inviteEnterCode => '招待コードを入力';

  @override
  String get inviteEnterCodeDesc => 'パートナーから受け取った\n6桁のコードを入力してください';

  @override
  String get inviteCodeHint => 'ABC123';

  @override
  String get inviteEmptyCode => '招待コードを入力してください';

  @override
  String get inviteInvalidCode => '招待コードが無効です';

  @override
  String get inviteJoinSuccess => '✅ 参加しました！';

  @override
  String get inviteJoinFailed => '参加に失敗しました';

  @override
  String get inviteNoMembers => 'まだメンバーがいません';

  @override
  String get inviteNoPartner => 'まだパートナーがいません';

  @override
  String get inviteNoPartnerDesc => 'パートナーから招待コードを\n受け取って参加しましょう';

  @override
  String get invitePartnerCardTitle => 'パートナーを招待して、\nふたりの記録を見える化しよう';

  @override
  String get invitePartnerCardDesc => '招待リンクを送るだけで、共有が始まります';

  @override
  String get invitePartnerCardButton => '招待リンクを共有';

  @override
  String get categoryEditTitle => 'カテゴリを編集';

  @override
  String get categoryAddTitle => 'カテゴリを追加';

  @override
  String get categoryEmpty => 'カテゴリがありません';

  @override
  String get categoryEmptyHint => '＋ボタンでカテゴリを追加しましょう';

  @override
  String get categoryMaxReached => 'カテゴリは最大12件までです';

  @override
  String get categoryAdded => 'カテゴリを追加しました';

  @override
  String get categoryUpdated => 'カテゴリを更新しました';

  @override
  String get categoryDeleteConfirm => 'カテゴリを削除しますか？';

  @override
  String get categoryDeleteNote => 'このカテゴリに紐づく記録は残ります。';

  @override
  String get categoryDeleted => 'カテゴリを削除しました';

  @override
  String get categoryStandardNote => '※ このカテゴリは標準カテゴリのため削除できません';

  @override
  String get categoryOrderSaved => '並び順を保存しました';

  @override
  String get categoryEmoji => '絵文字';

  @override
  String get categorySelectEmoji => 'タップしてアイコンを選ぶ';

  @override
  String get categorySelectEmojiTitle => 'アイコンを選択';

  @override
  String get categoryName => 'カテゴリ名';

  @override
  String get categoryNameHint => '例：お弁当作り';

  @override
  String get categoryDuration => '所要時間（分）';

  @override
  String get categorySelectDuration => '所要時間を選択';

  @override
  String get categoryNameEmpty => 'カテゴリ名を入力してください';

  @override
  String get categoryEmojiEmpty => '絵文字を選択してください';

  @override
  String get categoryInvalidTime => '正しい時間を入力してください';

  @override
  String get gratitudeHistoryTitle => '📮 貰った感謝一覧';

  @override
  String get gratitudeEmpty => '感謝カードはまだありません';

  @override
  String get gratitudeSender => '送信者';

  @override
  String get nicknameChangeTitle => 'ニックネーム変更';

  @override
  String get nicknameLabel => 'ニックネーム';

  @override
  String get nicknameInputHint => 'ニックネームを入力';

  @override
  String get nicknameEmpty => 'ニックネームを入力してください';

  @override
  String get nicknameSaved => '✅ 変更を保存しました';

  @override
  String get nicknameNote => 'ℹ️ ニックネームは全画面で即時反映されます';

  @override
  String get albumTitle => 'アルバム';

  @override
  String get albumOurAlbum => 'ふたりのアルバム';

  @override
  String get albumRecordsOnly => '記録のみ';

  @override
  String get albumGratitudeOnly => '感謝のみ';

  @override
  String get albumNoItems => 'まだアルバムがありません';

  @override
  String get albumNoItemsDesc => '記録や感謝が\nアルバムに表示されます';

  @override
  String get albumRecord => '記録';

  @override
  String get albumGratitude => '感謝';

  @override
  String albumMemberTime(String name, int minutes) {
    return '$name • $minutes分';
  }

  @override
  String albumToday(String time) {
    return '今日 $time';
  }

  @override
  String albumYesterday(String time) {
    return '昨日 $time';
  }

  @override
  String albumDaysAgo(int days) {
    return '$days日前';
  }

  @override
  String get recordListTitle => '記録一覧';

  @override
  String get recordListLoginRequired => 'ログインが必要です';

  @override
  String get recordListNoRecords => '記録がありません';

  @override
  String recordListTotalMinutes(int minutes) {
    return '($minutes分)';
  }

  @override
  String get recordListTotalCost => '総コスト';

  @override
  String get chartPast6Months => '過去記録（6ヶ月分）';

  @override
  String get chartBreakdown => '内訳';

  @override
  String get chartNoData => 'まだデータがありません';

  @override
  String get chartStartRecording => '記録をしてみましょう';

  @override
  String get chartInvitePartner => 'パートナーを招待しよう';

  @override
  String get chartInvitePartnerDesc => 'ふたりの推移を確認できるようになります';

  @override
  String get chartNoDataYet => 'まだデータがありません 😌';

  @override
  String get chartKeepRecording => '記録を続けて推移を確認しましょう';

  @override
  String chartCountTimes(String name, int count) {
    return '$name\n$count回';
  }

  @override
  String get errorOccurred => 'エラーが発生しました';

  @override
  String errorWithMessage(String message) {
    return 'エラー: $message';
  }

  @override
  String get operationFailed => '操作に失敗しました';

  @override
  String get addFailed => '追加に失敗しました';

  @override
  String get updateFailed => '更新に失敗しました';

  @override
  String get deleteFailed => '削除に失敗しました';

  @override
  String get saveFailed => '保存に失敗しました';

  @override
  String get orderSaveFailed => '並び順の保存に失敗しました';

  @override
  String get settingsNotificationDebug => '開発者向け通知診断';

  @override
  String get settingsAuthProviderNotFound => '認証プロバイダーが見つかりません';

  @override
  String get sender => '送信者';

  @override
  String get categoryLoadFailed => 'カテゴリの読み込みに失敗しました';

  @override
  String get now => '今';

  @override
  String get timeAgoJust => 'たった今';

  @override
  String timeAgoDays(int days) {
    return '$days日前';
  }

  @override
  String timeAgoHours(int hours) {
    return '$hours時間前';
  }

  @override
  String timeAgoMinutes(int minutes) {
    return '$minutes分前';
  }

  @override
  String totalHours(String hours) {
    return '$hours時間';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes分';
  }

  @override
  String get gratitudeCardSent => '感謝カードを送信しました';

  @override
  String get urlOpenFailed => 'URLを開けませんでした';

  @override
  String get alreadyJoinedHousehold => '既にこの世帯に参加しています';

  @override
  String get categoryCooking => '料理';

  @override
  String get categoryCleaning => '掃除';

  @override
  String get categoryLaundry => '洗濯';

  @override
  String get categoryDishes => '食器洗い';

  @override
  String get categoryShopping => '買い物';

  @override
  String get categoryChildcare => '育児';
}
