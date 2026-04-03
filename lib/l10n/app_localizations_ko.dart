// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get appName => 'Famica';

  @override
  String get appTagline => '둘의 노력을 10초 만에 기록';

  @override
  String get navRecord => '기록';

  @override
  String get navCouple => '둘이서';

  @override
  String get navLetter => '편지';

  @override
  String get navSettings => '설정';

  @override
  String get you => '나';

  @override
  String get partner => '파트너';

  @override
  String get save => '저장';

  @override
  String get cancel => '취소';

  @override
  String get delete => '삭제';

  @override
  String get close => '닫기';

  @override
  String get error => '오류';

  @override
  String get loading => '로딩 중...';

  @override
  String get logout => '로그아웃';

  @override
  String get unset => '미설정';

  @override
  String get uncategorized => '미분류';

  @override
  String get other => '기타';

  @override
  String get all => '전체';

  @override
  String get send => '보내기';

  @override
  String get copy => '복사';

  @override
  String get share => '공유';

  @override
  String get join => '참여';

  @override
  String get members => '멤버';

  @override
  String get today => '이번 달';

  @override
  String get task => '작업';

  @override
  String get authEmailHint => 'example@mail.com';

  @override
  String get authEmailLabel => '이메일';

  @override
  String get authPasswordLabel => '비밀번호';

  @override
  String get authPasswordHint => '6자 이상';

  @override
  String get authNicknameLabel => '닉네임';

  @override
  String get authNicknameHint => '예: 지민';

  @override
  String get authNicknameHelper => '앱에서 표시되는 이름입니다';

  @override
  String get authHasInviteCode => '초대 코드가 있습니다';

  @override
  String get authInviteCodeLabel => '초대 코드';

  @override
  String get authInviteCodeHint => '예: ABC123';

  @override
  String get authInviteCodeHelper => '파트너에게 받은 코드';

  @override
  String get authHouseholdNameLabel => '커플명 / 가구명';

  @override
  String get authHouseholdNameHint => '예: 지민 & 수아';

  @override
  String get authHouseholdNameHelper => '둘이 공유하는 그룹 이름입니다';

  @override
  String get authSignUp => '회원가입';

  @override
  String get authLoginOrSignUp => '로그인 / 회원가입';

  @override
  String get authSwitchToLogin => '기존 계정으로 로그인';

  @override
  String get authSignUpNote => '※ 닉네임은 앱에서 표시됩니다';

  @override
  String get authLoginNote => '※ 기존 사용자는 로그인,\n신규 사용자는 자동으로 가입됩니다';

  @override
  String get authErrorEmptyFields => '이메일과 비밀번호를 입력해 주세요';

  @override
  String get authErrorEmptyNickname => '닉네임을 입력해 주세요';

  @override
  String get authErrorEmptyHousehold => '커플명을 입력해 주세요';

  @override
  String get authErrorInvalidEmail => '이메일 형식이 올바르지 않습니다';

  @override
  String get authErrorWeakPassword => '비밀번호는 6자 이상이어야 합니다';

  @override
  String get authErrorUserNotFound => '계정을 찾을 수 없습니다. 닉네임을 입력하여 회원가입하세요';

  @override
  String get authErrorWrongPassword => '비밀번호가 틀렸습니다';

  @override
  String get authErrorDisabled => '이 계정은 비활성화되었습니다';

  @override
  String get authErrorTooMany => '요청이 너무 많습니다. 잠시 후 다시 시도해 주세요';

  @override
  String get authErrorNetwork => '네트워크 오류가 발생했습니다';

  @override
  String get authErrorLogin => '로그인 오류';

  @override
  String get authErrorUnexpected => '예상치 못한 오류가 발생했습니다';

  @override
  String get authErrorEmailInUse => '이미 사용 중인 이메일입니다';

  @override
  String get authErrorWeakPasswordSignUp =>
      '비밀번호가 너무 약합니다. 더 강력한 비밀번호를 설정해 주세요';

  @override
  String get authErrorOperationNotAllowed => '이메일/비밀번호 인증이 활성화되지 않았습니다';

  @override
  String get authErrorSignUp => '회원가입 오류';

  @override
  String get authLoginSuccess => '로그인에 성공했습니다';

  @override
  String get authSignUpSuccess => '가입이 완료되었습니다! Famica에 오신 것을 환영합니다!';

  @override
  String get authInviteSuccess => '초대 코드를 통한 가입이 완료되었습니다!';

  @override
  String get authInviteNotFound => '초대 코드를 찾을 수 없습니다';

  @override
  String get authInviteUsed => '이 초대 코드는 이미 사용되었습니다';

  @override
  String get authErrorCreateUser => '사용자 생성에 실패했습니다';

  @override
  String get authErrorHouseholdNotFound => '가구를 찾을 수 없습니다';

  @override
  String get mainInitSetup => '초기 설정 중...';

  @override
  String get mainCreatingUser => '사용자 정보를 생성하고 있습니다';

  @override
  String get mainLoadingUser => '사용자 정보를 불러오는 중...';

  @override
  String get mainPreparingHousehold => '가구 정보를 준비 중...';

  @override
  String get mainWaitingHousehold => '가구 설정을 기다리고 있습니다';

  @override
  String get mainErrorOccurred => '오류가 발생했습니다';

  @override
  String get mainFirebaseError => 'Firebase 초기화 오류';

  @override
  String get mainAuthError => '인증 오류';

  @override
  String get quickRecord => '빠른 기록';

  @override
  String get quickRecordPanelEdit => '패널 편집';

  @override
  String get quickRecordTodayEffort => '오늘의 노력';

  @override
  String quickRecordCountTimes(int count) {
    return '$count회';
  }

  @override
  String quickRecordMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String get quickRecordRecentRecords => '최근 기록';

  @override
  String get quickRecordSeeAll => '전체 보기';

  @override
  String get quickRecordNoRecords => '아직 기록이 없습니다';

  @override
  String get quickRecordNoName => '이름 없음';

  @override
  String get quickRecordAdded => '기록을 추가했습니다!';

  @override
  String get quickRecordThanks => '감사를 보냈습니다!';

  @override
  String get quickRecordCostRecord => '비용 기록하기';

  @override
  String get quickRecordSelectTime => '시간 선택';

  @override
  String quickRecordError(String error) {
    return '오류: $error';
  }

  @override
  String get costRecordTitle => '비용 기록';

  @override
  String get costRecordAmount => '금액';

  @override
  String get costRecordAmountHint => '1000';

  @override
  String get costRecordPurpose => '용도';

  @override
  String get costRecordPurposeHint => '예: 식재료, 생활용품, 교통비 등';

  @override
  String get costRecordPayer => '결제한 사람';

  @override
  String get costRecordEmptyAmount => '금액을 입력해 주세요';

  @override
  String get costRecordInvalidAmount => '올바른 금액을 입력해 주세요';

  @override
  String get costRecordSuccess => '비용을 기록했습니다!';

  @override
  String get costRecordFailed => '저장에 실패했습니다';

  @override
  String get costRecordNoPurpose => '용도 미기입';

  @override
  String get coupleActionTip => '행동 팁';

  @override
  String get coupleThisMonth => '이번 달';

  @override
  String get coupleSendGratitude => '감사 메시지 보내기';

  @override
  String get coupleSendGratitudeDesc => '파트너에게 감사의 마음을 전하세요';

  @override
  String get coupleGratitudeReceived => '감사 카드가 도착했습니다';

  @override
  String get coupleTapToRead => '탭하여 읽기';

  @override
  String get coupleMonthlyBreakdown => '이번 달 집안일 내역 (카테고리별 합계)';

  @override
  String get coupleMonthlyCost => '이번 달 비용 (지출)';

  @override
  String get coupleTotal => '합계';

  @override
  String get coupleNoSuggestion => '이번 달 제안이 아직 없습니다';

  @override
  String get coupleSuggestion => '제안';

  @override
  String get coupleSuggestionOverworked =>
      '당신에게 부담이 조금 치우친 것 같아요.\n가끔은 파트너에게 맡기고 쉬어도 좋아요.';

  @override
  String get coupleSuggestionPartnerOverworked =>
      '파트너에게 부담이 조금 치우친 것 같아요.\n감사의 마음을 전해 보세요.';

  @override
  String get coupleSuggestionBalanced => '요리 밸런스가 좋네요!\n이대로 계속해 나가요!';

  @override
  String get couplePartnerNotFound => '파트너를 찾을 수 없습니다';

  @override
  String get coupleSendGratitudeCard => '감사 카드 보내기';

  @override
  String get coupleSendTo => '받는 사람:';

  @override
  String get coupleMessage => '메시지';

  @override
  String get coupleMessageHint => '예: 항상 설거지 해줘서 고마워!';

  @override
  String get coupleEmptyMessage => '메시지를 입력해 주세요';

  @override
  String get coupleSendFailed => '전송에 실패했습니다';

  @override
  String get letterTitle => '파트너의 감사 메시지';

  @override
  String get letterPleaseLogin => '로그인해 주세요';

  @override
  String get letterNoMessages => '아직 감사 메시지가 없습니다';

  @override
  String get letterUnread => '읽지 않음';

  @override
  String letterFromUser(String name) {
    return '$name님으로부터';
  }

  @override
  String get settingsInvitePartner => '파트너 초대';

  @override
  String get settingsChangeNickname => '닉네임 변경';

  @override
  String get settingsPrivacyPolicy => '개인정보 처리방침';

  @override
  String get settingsHelp => '도움말 · 문의';

  @override
  String get settingsTerms => '이용약관';

  @override
  String get settingsDeleteAccount => '계정 삭제';

  @override
  String get settingsDeleteConfirm => '계정을 삭제하시겠습니까?';

  @override
  String get settingsDeleteWarning => '삭제하면 다음 정보가 완전히 삭제됩니다';

  @override
  String get settingsDeleteRecords => '• 모든 기록 데이터';

  @override
  String get settingsDeletePartner => '• 파트너 공유 정보';

  @override
  String get settingsDeleteIrreversible => '이 작업은 되돌릴 수 없습니다';

  @override
  String get settingsDeleteButton => '삭제하기';

  @override
  String get settingsDeleting => '계정을 삭제하고 있습니다...';

  @override
  String get settingsDeleteUserNotFound => '사용자를 찾을 수 없습니다';

  @override
  String get settingsDeleteFirestoreFailed => 'Firestore 데이터 삭제에 실패했습니다';

  @override
  String get settingsDeleteFailed => '삭제에 실패했습니다';

  @override
  String get settingsReauthRequired => '재인증이 필요합니다';

  @override
  String get settingsReauthFailed => '재인증에 실패했습니다';

  @override
  String get settingsReauthError => '재인증 중 오류가 발생했습니다';

  @override
  String get settingsReauthInstruction =>
      '이메일/비밀번호로 로그인한 경우,\n한 번 로그아웃 후 다시 로그인한 다음\n계정 삭제를 실행해 주세요.';

  @override
  String get settingsUnsupportedAuth => '지원되지 않는 인증 방식입니다';

  @override
  String get settingsLogoutConfirm => '로그아웃하시겠습니까?\n다시 로그인해야 합니다.';

  @override
  String get settingsLogoutButton => '로그아웃하기';

  @override
  String get settingsNicknameChange => '닉네임 변경';

  @override
  String get settingsNicknameInput => '닉네임 입력';

  @override
  String get settingsNicknameEmpty => '닉네임을 입력해 주세요';

  @override
  String get settingsNicknameSaved => '변경사항을 저장했습니다';

  @override
  String get settingsNicknameError => '오류가 발생했습니다';

  @override
  String get settingsNicknameNote => '닉네임은 모든 화면에 즉시 반영됩니다';

  @override
  String get settingsSaveChanges => '변경사항 저장';

  @override
  String get inviteTitle => '파트너 초대';

  @override
  String get inviteDescription => '파트너를 Famica에 초대하세요!';

  @override
  String get inviteYourCode => '나의 초대 코드';

  @override
  String get inviteCopied => '초대 코드가 복사되었습니다';

  @override
  String get inviteShareSubject => 'Famica 초대';

  @override
  String get inviteEnterCode => '초대 코드 입력';

  @override
  String get inviteEnterCodeDesc => '파트너에게 받은\n6자리 코드를 입력하세요';

  @override
  String get inviteCodeHint => 'ABC123';

  @override
  String get inviteEmptyCode => '초대 코드를 입력해 주세요';

  @override
  String get inviteInvalidCode => '유효하지 않은 초대 코드입니다';

  @override
  String get inviteJoinSuccess => '참여했습니다!';

  @override
  String get inviteJoinFailed => '참여에 실패했습니다';

  @override
  String get inviteNoMembers => '아직 멤버가 없습니다';

  @override
  String get inviteNoPartner => '아직 파트너가 없습니다';

  @override
  String get inviteNoPartnerDesc => '파트너에게 초대 코드를 받아\n참여하세요';

  @override
  String get invitePartnerCardTitle => '파트너를 초대하고\n둘의 기록을 시각화하세요';

  @override
  String get invitePartnerCardDesc => '초대 링크를 보내기만 하면 공유가 시작됩니다';

  @override
  String get invitePartnerCardButton => '초대 링크 공유';

  @override
  String get categoryEditTitle => '카테고리 편집';

  @override
  String get categoryAddTitle => '카테고리 추가';

  @override
  String get categoryEmpty => '카테고리가 없습니다';

  @override
  String get categoryEmptyHint => '+ 버튼으로 카테고리를 추가하세요';

  @override
  String get categoryMaxReached => '카테고리는 최대 12개까지입니다';

  @override
  String get categoryAdded => '카테고리를 추가했습니다';

  @override
  String get categoryUpdated => '카테고리를 업데이트했습니다';

  @override
  String get categoryDeleteConfirm => '카테고리를 삭제하시겠습니까?';

  @override
  String get categoryDeleteNote => '이 카테고리에 연결된 기록은 유지됩니다.';

  @override
  String get categoryDeleted => '카테고리를 삭제했습니다';

  @override
  String get categoryStandardNote => '※ 기본 카테고리는 삭제할 수 없습니다';

  @override
  String get categoryOrderSaved => '순서를 저장했습니다';

  @override
  String get categoryEmoji => '이모지';

  @override
  String get categorySelectEmoji => '탭하여 아이콘 선택';

  @override
  String get categorySelectEmojiTitle => '아이콘 선택';

  @override
  String get categoryName => '카테고리명';

  @override
  String get categoryNameHint => '예: 도시락 만들기';

  @override
  String get categoryDuration => '소요시간 (분)';

  @override
  String get categorySelectDuration => '소요시간 선택';

  @override
  String get categoryNameEmpty => '카테고리명을 입력해 주세요';

  @override
  String get categoryEmojiEmpty => '이모지를 선택해 주세요';

  @override
  String get categoryInvalidTime => '올바른 시간을 입력해 주세요';

  @override
  String get gratitudeHistoryTitle => '받은 감사 목록';

  @override
  String get gratitudeEmpty => '아직 감사 카드가 없습니다';

  @override
  String get gratitudeSender => '보낸 사람';

  @override
  String get nicknameChangeTitle => '닉네임 변경';

  @override
  String get nicknameLabel => '닉네임';

  @override
  String get nicknameInputHint => '닉네임 입력';

  @override
  String get nicknameEmpty => '닉네임을 입력해 주세요';

  @override
  String get nicknameSaved => '변경사항을 저장했습니다';

  @override
  String get nicknameNote => '닉네임은 모든 화면에 즉시 반영됩니다';

  @override
  String get albumTitle => '앨범';

  @override
  String get albumOurAlbum => '둘의 앨범';

  @override
  String get albumRecordsOnly => '기록만';

  @override
  String get albumGratitudeOnly => '감사만';

  @override
  String get albumNoItems => '아직 앨범이 없습니다';

  @override
  String get albumNoItemsDesc => '기록과 감사가\n앨범에 표시됩니다';

  @override
  String get albumRecord => '기록';

  @override
  String get albumGratitude => '감사';

  @override
  String albumMemberTime(String name, int minutes) {
    return '$name • $minutes분';
  }

  @override
  String albumToday(String time) {
    return '오늘 $time';
  }

  @override
  String albumYesterday(String time) {
    return '어제 $time';
  }

  @override
  String albumDaysAgo(int days) {
    return '$days일 전';
  }

  @override
  String get recordListTitle => '기록 목록';

  @override
  String get recordListLoginRequired => '로그인이 필요합니다';

  @override
  String get recordListNoRecords => '기록이 없습니다';

  @override
  String recordListTotalMinutes(int minutes) {
    return '($minutes분)';
  }

  @override
  String get recordListTotalCost => '총 비용';

  @override
  String get chartPast6Months => '과거 기록 (6개월)';

  @override
  String get chartBreakdown => '내역';

  @override
  String get chartNoData => '아직 데이터가 없습니다';

  @override
  String get chartStartRecording => '기록을 시작해 보세요';

  @override
  String get chartInvitePartner => '파트너를 초대하세요';

  @override
  String get chartInvitePartnerDesc => '둘의 추이를 확인할 수 있게 됩니다';

  @override
  String get chartNoDataYet => '아직 데이터가 없습니다';

  @override
  String get chartKeepRecording => '기록을 계속하여 추이를 확인하세요';

  @override
  String chartCountTimes(String name, int count) {
    return '$name\n$count회';
  }

  @override
  String get errorOccurred => '오류가 발생했습니다';

  @override
  String errorWithMessage(String message) {
    return '오류: $message';
  }

  @override
  String get operationFailed => '작업에 실패했습니다';

  @override
  String get addFailed => '추가에 실패했습니다';

  @override
  String get updateFailed => '업데이트에 실패했습니다';

  @override
  String get deleteFailed => '삭제에 실패했습니다';

  @override
  String get saveFailed => '저장에 실패했습니다';

  @override
  String get orderSaveFailed => '순서 저장에 실패했습니다';

  @override
  String get settingsNotificationDebug => '개발자용 알림 진단';

  @override
  String get settingsAuthProviderNotFound => '인증 제공자를 찾을 수 없습니다';

  @override
  String get sender => '발신자';

  @override
  String get categoryLoadFailed => '카테고리 로드에 실패했습니다';

  @override
  String get now => '지금';

  @override
  String get timeAgoJust => '방금';

  @override
  String timeAgoDays(int days) {
    return '$days일 전';
  }

  @override
  String timeAgoHours(int hours) {
    return '$hours시간 전';
  }

  @override
  String timeAgoMinutes(int minutes) {
    return '$minutes분 전';
  }

  @override
  String totalHours(String hours) {
    return '$hours시간';
  }

  @override
  String durationMinutes(int minutes) {
    return '$minutes분';
  }

  @override
  String get gratitudeCardSent => '감사 카드를 보냈습니다';

  @override
  String get urlOpenFailed => 'URL을 열 수 없습니다';

  @override
  String get alreadyJoinedHousehold => '이미 이 가구의 구성원입니다';

  @override
  String get categoryCooking => '요리';

  @override
  String get categoryCleaning => '청소';

  @override
  String get categoryLaundry => '빨래';

  @override
  String get categoryDishes => '설거지';

  @override
  String get categoryShopping => '장보기';

  @override
  String get categoryChildcare => '육아';
}
