# Famica App Store プライバシー申告 vs 実装コード 差異監査報告書

**調査日時**: 2025年12月25日  
**調査対象**: Famicaアプリ コードベース全体  
**調査目的**: App Store Connect「App Privacy」申告内容とコード実装の差異確認

---

## ✅ 一致している点（申告通り実装されている）

### 1. Firebase Auth / Firestore によるデータ収集
**申告**: UID、email、家事記録、感謝メッセージ、household統計データを収集  
**実装**: ✅ **完全一致**

**確認ファイル**: `lib/services/firestore_service.dart`

**Firestoreコレクション構造**:
```
users/{uid}
  - displayName: string
  - nickname: string
  - email: string
  - householdId: string
  - role: string
  - lifeStage: string (couple/newlywed/baby)
  - plan: string (free/plus)
  - trialUsed: boolean
  - trialEndDate: Timestamp?
  - planStartDate: Timestamp?
  - productId: string?
  - transactionId: string?
  - totalThanksReceived: int
  - title: string (称号バッジ)
  - createdAt: Timestamp

users/{uid}/customCategories/{categoryId}
  - name: string
  - emoji: string
  - defaultMinutes: int
  - isVisible: boolean
  - order: int

households/{householdId}
  - name: string
  - inviteCode: string
  - lifeStage: string
  - members: array<object>
    - uid: string
    - name: string
    - nickname: string
    - role: string
    - avatar: string
  - plan: string?
  - planOwner: string?

households/{householdId}/records/{recordId}
  - memberId: string (UID)
  - memberName: string
  - category: string
  - task: string
  - timeMinutes: int
  - cost: int
  - note: string
  - month: string (YYYY-MM)
  - thankedBy: array<string> (UIDs)
  - createdAt: Timestamp

households/{householdId}/thanks/{thanksId}
  - fromUid: string
  - fromName: string
  - toUid: string
  - toName: string
  - recordId: string
  - emoji: string
  - message: string
  - createdAt: Timestamp

households/{householdId}/aiCoach/{dateKey}
  - {userId}: object
    - message1: string
    - message2: string (Plus限定)
    - message3: string (Plus限定)
    - message4: string (Plus限定)
    - createdAt: Timestamp

gratitudeMessages/{messageId}
  - fromUserId: string
  - fromUserName: string
  - toUserId: string
  - toName: string
  - message: string
  - isRead: boolean
  - createdAt: Timestamp
```

**個人情報の保存状況**:
- ✅ UID: Firebase Auth自動生成、全記録に紐付け
- ✅ Email: usersコレクションに保存
- ✅ Nickname/DisplayName: users・households両方に保存
- ✅ 家事記録: households/{householdId}/recordsに保存
- ✅ 感謝メッセージ: thanks・gratitudeMessagesに保存

---

### 2. Gemini API による外部送信
**申告**: 集計済み家事データのみ送信、個人特定情報（UID・メール）は送信しない  
**実装**: ✅ **完全一致**

**確認ファイル**: `lib/services/ai_coach_service.dart`

**送信データの詳細** (行331-391: `_collectHouseholdData()`):
```dart
// Gemini APIへの送信データ（プロンプト内に埋め込まれる）
{
  'totalRecords': int,  // 過去30日の記録数（集計値のみ）
  'currentMonth': {
    'myPercent': int,     // 担当割合（%）
    'partnerPercent': int,
    'myName': string,     // 「あなた」「パートナー」等の表示名（匿名）
    'partnerName': string,
  },
  'categoryTime': {      // カテゴリ別時間（集計値）
    '料理': int (分),
    '掃除': int (分),
    ...
  },
}
```

**送信されないデータ**:
- ❌ UID（完全除外）
- ❌ Email（完全除外）
- ❌ 記録の個別詳細（task名・note・日時等）
- ❌ householdId（完全除外）

**APIエンドポイント**:
```dart
// ai_coach_service.dart 行21-22
static const String geminiApiKey = 'AIzaSyD6GHNt4zJvN9m14t-Gv4ly80pIjZXHfrA';
static const String geminiEndpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent';
```

**プライバシー適合性**: ✅ **問題なし**  
→ 集計・統計値のみを送信し、個人特定可能な情報は含まれない

---

### 3. StoreKit / In-App Purchase
**申告**: Famica Plus サブスクリプション、購入情報はユーザーに関連付け  
**実装**: ✅ **完全一致**

**確認ファイル**: `lib/services/plan_service.dart`

**購入情報の保存** (行244-270: `upgradeToPlusWithPurchase()`):
```dart
// users/{uid} に保存される購入情報
{
  'plan': 'plus',
  'planStartDate': Timestamp,
  'productId': string,  // 例: famica_plus_monthly2025
  'transactionId': string,  // StoreKitのトランザクションID
  'trialUsed': boolean,
  'updatedAt': Timestamp,
}
```

**商品ID**:
```dart
// paywall_screen.dart 行28-29
static const String monthlyProductId = 'famica_plus_monthly2025';
static const String yearlyProductId = 'famica_plus_yearly2026';
```

**プライバシー適合性**: ✅ **問題なし**  
→ 購入情報は適切にユーザーUIDに紐付けて保存

---

### 4. 端末情報・OS判定
**申告**: 端末情報（OS、端末モデル）を自動取得  
**実装**: ✅ **限定的に実装（OS判定のみ）**

**確認ファイル**: `lib/widgets/banner_ad_widget.dart`

**Platform判定のみ実装**:
```dart
// banner_ad_widget.dart 行129-148: _isEmulatorDevice()
if (Platform.isAndroid) { ... }
if (Platform.isIOS) { ... }
```

**DeviceInfoパッケージは未使用**:
- ❌ device_info_plus パッケージは`pubspec.yaml`に存在しない
- ❌ 端末モデル名・OSバージョン・デバイスID等は取得していない

**実際の取得情報**:
- ✅ OS種別（Android/iOS）のみ（Flutter標準のPlatform判定）
- ❌ 端末モデル名: 取得していない
- ❌ OSバージョン: 取得していない
- ❌ デバイスID: 取得していない

**プライバシー適合性**: ✅ **問題なし**  
→ OS判定は最小限、詳細な端末情報は取得していない

---

## ⚠️ 要注意（申告はあるが実装が弱い / 曖昧）

### 1. Google Analytics for Firebase
**申告**: 「Google Analytics for Firebase」を使用してイベント送信  
**実装**: ❌ **未実装**

**調査結果**:
```bash
# コード内検索結果
$ grep -r "FirebaseAnalytics" lib/
$ grep -r "firebase_analytics" lib/
$ grep -r "logEvent" lib/

→ 0件ヒット
```

**pubspec.yaml**:
```yaml
dependencies:
  firebase_core: 3.8.0
  cloud_firestore: 5.4.4
  firebase_auth: ^5.3.3
  firebase_storage: 12.3.4
  # ❌ firebase_analytics パッケージが存在しない
```

**lib/services/analytics_service.dart**:
```dart
/// Famica Phase 5: 分析・集計サービス
/// memberIdごとの記録集計、時間・回数の計算を担当
///
/// ⚠️ 現在未使用 - 将来の統計機能強化で使用予定
class AnalyticsService {
  // Firestore内部での集計処理のみ
  // 外部へのイベント送信は一切なし
}
```

**プライバシー適合性**: ⚠️ **申告の修正推奨**  
→ 現在FirebaseAnalyticsは使用していない  
→ App Store Connect申告から削除するか、将来実装予定を明記

**推奨対応**:
- Option 1: App Store Connect申告から「Google Analytics for Firebase」を削除
- Option 2: コード内でFirebaseAnalyticsを実装してイベント送信を開始

---

### 2. AdMob 広告ID・ATT対応
**申告**: 「広告ID（AdMob）」を取得  
**実装**: ⚠️ **部分実装（本番広告未表示、ATT未対応）**

**確認ファイル**: 
- `lib/widgets/banner_ad_widget.dart`
- `ios/Runner/Info.plist`

**現在の実装状況**:

#### (1) 広告ユニットID（本番ID設定済み）
```xml
<!-- Info.plist 行51-52 -->
<key>GADApplicationIdentifier</key>
<string>ca-app-pub-3184270565267183~2634862619</string>
```

#### (2) 広告表示コード（テスト広告のみ）
```dart
// banner_ad_widget.dart 行129-131
// テスト広告ID（広告表示確認用）
final adUnitId = Platform.isAndroid
    ? 'ca-app-pub-3940256099942544/9214589741' // Androidテスト用バナー
    : 'ca-app-pub-3940256099942544/2934735716'; // iOSテスト用バナー
```

**⚠️ コード上の広告IDはテスト用のまま**  
→ 本番環境でも広告収益は発生しない状態

#### (3) ATT（App Tracking Transparency）対応状況
```xml
<!-- Info.plist -->
<!-- ❌ NSUserTrackingUsageDescription が存在しない -->
```

**iOS 14.5以降の広告ID取得ルール**:
- ATTプロンプト（NSUserTrackingUsageDescription）が必須
- プロンプトなしで広告IDを取得すると **審査リジェクトの可能性**

**プライバシー適合性**: ⚠️ **要対応（中リスク）**

**推奨対応（2つのオプション）**:

**Option 1: ATT対応を実装（広告収益化する場合）**
```xml
<!-- Info.plist に追加 -->
<key>NSUserTrackingUsageDescription</key>
<string>より良い広告体験のために使用します</string>
```
```dart
// banner_ad_widget.dart のadUnitIdを本番IDに変更
final adUnitId = Platform.isAndroid
    ? 'ca-app-pub-3184270565267183/XXXXXX' // 本番Android広告ID
    : 'ca-app-pub-3184270565267183/YYYYYY'; // 本番iOS広告ID
```

**Option 2: AdMobを完全削除（広告収益化しない場合）**
- `pubspec.yaml`から`google_mobile_ads`を削除
- `banner_ad_widget.dart`を削除
- `Info.plist`から`GADApplicationIdentifier`を削除
- App Store Connect申告から「広告ID」を削除

**現状の審査リスク**: 🟡 **中程度**  
→ テスト広告のみでATT未対応の場合、審査時に指摘される可能性あり

---

## ❌ 不一致（未申告だが実装されている or 申告あるが未実装）

### 該当なし

すべての主要データ収集・外部送信は申告内容と一致しています。

---

## 📝 修正不要 / 申告修正のみでOKな点

### 1. IPアドレスの自動取得
**申告**: 「IPアドレス」を自動取得  
**実装**: ✅ **Firebase経由で自動取得（明示的コードなし）**

**説明**:
- Firebase Auth / Firestoreへの接続時に、HTTPリクエストヘッダーからIPアドレスが自動取得される
- アプリ側のコードで明示的に取得・送信はしていない
- Firebaseサーバー側のログに記録される可能性がある

**プライバシー適合性**: ✅ **問題なし**  
→ 申告通り、IPアドレスは自動取得される（Firebase標準動作）

---

### 2. 画面遷移・操作ログ
**申告**: 「利用ログ（画面遷移・操作）」を取得  
**実装**: ❌ **現在は取得していない**

**調査結果**:
- FirebaseAnalyticsが未実装のため、画面遷移イベントは送信されていない
- go_routerによる画面遷移ログはローカルのみ（外部送信なし）
- ボタンクリック等の操作ログも外部送信していない

**プライバシー適合性**: ⚠️ **申告の修正推奨**  
→ 現在は取得していないため、App Store Connect申告から削除するか、将来実装予定を明記

---

## 🧾 総合判定

### App Store審査: **要修正（中リスク）**

#### 修正が必要な項目（優先度順）

**【優先度: 高】AdMob ATT対応**
- **問題**: iOS 14.5以降、ATTプロンプトなしで広告IDを取得すると審査リジェクト
- **現状**: `NSUserTrackingUsageDescription`が`Info.plist`に存在しない
- **対応**:
  - Option 1: ATT実装（Info.plistに追加 + 本番広告ID設定）
  - Option 2: AdMob完全削除（テスト広告のままなら収益化不可）
- **審査リスク**: 🔴 **高**（ATT未対応は即リジェクトの可能性）

**【優先度: 中】Google Analytics for Firebase**
- **問題**: 申告に「Google Analytics for Firebase」があるが未実装
- **現状**: firebase_analyticsパッケージが存在しない
- **対応**:
  - Option 1: App Store Connect申告から削除
  - Option 2: FirebaseAnalyticsを実装
- **審査リスク**: 🟡 **中**（虚偽申告と見なされる可能性）

**【優先度: 低】利用ログ（画面遷移・操作）**
- **問題**: 申告に「利用ログ」があるが未実装
- **現状**: FirebaseAnalytics未実装のため、イベント送信なし
- **対応**: App Store Connect申告から削除
- **審査リスク**: 🟢 **低**（実害なし、申告修正のみでOK）

---

### 理由

#### ✅ 良い点
1. **Firebase/Firestoreのデータ構造が明確**  
   - 保存フィールドが申告内容と完全一致
   - UID・Email・家事記録・感謝メッセージが適切に管理されている

2. **Gemini APIの個人情報保護が徹底**  
   - 集計・統計値のみを送信
   - UID・Email・個別記録詳細は完全除外
   - プライバシー配慮が高い実装

3. **StoreKit購入情報の保存が適切**  
   - 購入情報がユーザーUIDに正しく紐付けられている
   - transactionIdの保存により購入履歴の追跡が可能

#### ⚠️ 改善が必要な点
1. **AdMob ATT未対応（最重要）**  
   - iOS 14.5以降、ATTプロンプトなしでは広告ID取得不可
   - 現状のままでは審査リジェクトの可能性が高い
   - テスト広告IDのままでは収益化もできない

2. **Google Analytics未実装なのに申告あり**  
   - firebase_analyticsパッケージが存在しない
   - 「虚偽申告」と見なされる可能性
   - 申告削除 or 実装が必要

3. **利用ログ申告があるが未実装**  
   - 画面遷移・操作ログは外部送信していない
   - 実害はないが、申告の整合性のため削除推奨

---

### 推奨対応アクション

#### 📋 審査前に必ず実施すべきこと

**1. AdMob対応を決定する**
```
IF 広告収益化する:
  → Info.plistにNSUserTrackingUsageDescriptionを追加
  → banner_ad_widget.dartのadUnitIdを本番IDに変更
  → ATTプロンプトのタイミングを設計

ELSE IF 広告収益化しない:
  → google_mobile_adsパッケージを削除
  → banner_ad_widget.dartを削除
  → Info.plistからGADApplicationIdentifierを削除
  → App Store Connect申告から「広告ID」を削除
```

**2. App Store Connect プライバシー申告を修正**
```
削除すべき項目:
- Google Analytics for Firebase（未実装のため）
- 利用ログ（画面遷移・操作）（未実装のため）

残すべき項目:
- Firebase Auth / Firestore（実装済み）
- Gemini API（実装済み・個人情報なし）
- StoreKit / In-App Purchase（実装済み）
- IPアドレス（Firebase自動取得）
- 端末情報（OS判定のみ）
```

**3. 審査用テストアカウント情報の準備**
- Plus会員のテストアカウント
- Gemini API動作確認用のアカウント
- 招待コード機能のテスト方法

---

### 最終結論

**現状のままでは審査リジェクトの可能性が高い**

特に「AdMob ATT未対応」は致命的で、iOS 14.5以降のApp Store審査ガイドラインに抵触します。

**審査通過のための必須対応**:
1. ✅ AdMob対応を決定（ATT実装 or 完全削除）
2. ✅ App Store Connect プライバシー申告を実態に合わせて修正
3. ✅ テスト広告IDを本番IDに変更（広告収益化する場合）

上記3点を対応すれば、**審査通過可能**と判断します。

---

**調査完了日時**: 2025年12月25日 21:21  
**調査者**: Cline (AI Privacy Auditor)
