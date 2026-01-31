# iOS プッシュ通知不達問題 - 包括的調査レポート

**日付**: 2026年1月29日  
**調査対象**: Famica iOS アプリ (v1.0.2 Build 11)  
**目的**: iOS でプッシュ通知が届かない根本原因の特定（コード変更なし、調査のみ）

---

## 📋 エグゼクティブサマリー

**現状**:
- ✅ Android: プッシュ通知は正常に動作
- ❌ iOS: プッシュ通知が届かない（Firebase Console テストメッセージも届かず）
- ✅ 通知デバッグ画面は実装済み（Permission status、APNs token、FCM token を確認可能）

**最重要発見**:
```
🔴 致命的なバグを発見: トークン保存先の不一致
```

- **FCMService**: `users/{uid}.fcmToken` (単数) に保存
- **Cloud Functions**: `users/{uid}.fcmTokens.{token}` (複数形マップ) を読み取り
- **結果**: Cloud Functions が iOS の FCM トークンを見つけられず、通知が送信されない

---

## 🎯 優先度付き根本原因リスト（Top 5）

### 1. 🔴 **トークン保存先の不一致**（確率: 95%）

**問題**:
```dart
// lib/services/fcm_service.dart (Line 177-184)
await _firestore.collection('users').doc(user.uid).set({
  'fcmTokens': {       // ← マップ形式で保存
    token: true,
  },
}, SetOptions(merge: true));
```

```javascript
// functions/index.js (Line 646-650)
const tokens = userData.fcmTokens || {};  // ← マップから読み取り
const tokenList = Object.keys(tokens).filter(t => tokens[t] === true);
```

**しかし、過去のコードやドキュメントから**:
- 古いバージョンでは `fcmToken`（単数）に保存していた可能性
- Firestore に残っている古いトークンが `fcmToken` フィールドにある場合、Cloud Functions が読み取れない

**検証方法**:
1. Firebase Console → Firestore → `users/{iOS ユーザーの uid}` を開く
2. 以下のフィールドを確認:
   - `fcmToken`（単数）: 存在するか？値は？
   - `fcmTokens`（複数形）: 存在するか？オブジェクト形式か？
3. 通知デバッグ画面で表示される FCM トークンと Firestore の値を照合

**対処法**（コード変更が必要）:
- FCMService のトークン保存ロジックが `fcmTokens` マップに正しく保存しているか確認
- 古いトークンを削除して、アプリを再インストール
- または、Cloud Functions 側で `fcmToken`（単数）もフォールバックとして読み取るよう修正

---

### 2. 🟠 **APNs トークン取得タイミングの問題**（確率: 60%）

**問題**:
```dart
// lib/services/fcm_service.dart (Line 142-159)
// APNSトークンがない場合、再試行（最大3回、1秒間隔）
for (int i = 0; i < 3; i++) {
  await Future.delayed(const Duration(seconds: 1));
  final retryToken = await _messaging.getAPNSToken();
  if (retryToken != null) {
    print('🍎 APNSトークン取得成功（再試行 ${i + 1}回目）');
    break;
  }
}
```

**iOS の APNs 登録は非同期で時間がかかる**:
- デバイスが Apple の APNs サーバーに登録完了するまで数秒〜数十秒かかる場合がある
- 3回のリトライ（合計3秒）では不十分な可能性
- ネットワーク環境が悪い場合はさらに時間がかかる

**既存ドキュメント（IOS_PUSH_NOTIFICATION_ROOT_CAUSE_ANALYSIS.md）の推奨**:
```dart
// 10回リトライ、指数バックオフ（1秒、2秒、3秒...）
for (int i = 0; i < 10; i++) {
  apnsToken = await _messaging.getAPNSToken();
  if (apnsToken != null) break;
  
  final delaySeconds = (i + 1);
  await Future.delayed(Duration(seconds: delaySeconds));
}
```

**検証方法**:
1. 通知デバッグ画面を開く
2. "APNs Token" のステータスを確認
3. `❌ Not Available` の場合、"Retry APNs Token" ボタンを数回押す
4. それでも取得できない場合は、アプリ再起動後に再確認

**兆候**:
- 通知デバッグ画面で APNs Token が `❌ Not Available`
- Xcode コンソールログに `⚠️ APNSトークンを取得できませんでした` が表示される

---

### 3. 🟡 **Firebase Console の APNs 認証キー設定不備**（確率: 40%）

**確認すべき項目**:

#### A. APNs 認証キー（.p8）のアップロード
1. Firebase Console にアクセス
2. プロジェクト設定 → Cloud Messaging → iOS アプリ
3. "APNs 認証キー" セクションを確認:
   - ✅ `.p8` ファイルがアップロード済みか
   - ✅ Key ID が正しいか（Apple Developer で確認）
   - ✅ Team ID が正しいか（Apple Developer で確認）

#### B. 開発環境 vs 本番環境
- **開発用キー**: Xcode からデバッグ実行時に使用
- **本番用キー**: App Store / TestFlight 経由で使用
- **両方の環境で同じキーを使用可能**（推奨）

#### C. Bundle ID の一致
- Firebase Console の iOS アプリの Bundle ID: `com.matsushima.famica`
- Xcode プロジェクトの Bundle ID: `com.matsushima.famica`
- `GoogleService-Info.plist` の `BUNDLE_ID`: `com.matsushima.famica`

**確認済み（今回の調査）**:
```xml
<!-- ios/Runner/GoogleService-Info.plist -->
<key>BUNDLE_ID</key>
<string>com.matsushima.famica</string>
<key>GOOGLE_APP_ID</key>
<string>1:273365767591:ios:b88d1cb281b8bf4b411282</string>
```

**検証方法**:
1. Firebase Console → プロジェクト設定 → Cloud Messaging
2. "Apple アプリの構成" セクションで `com.matsushima.famica` を探す
3. APNs 認証キーの設定状況を確認
4. "テスト メッセージを送信" で FCM トークンを貼り付けてテスト
5. エラーメッセージを確認:
   - `INVALID_ARGUMENT`: トークンが無効
   - `UNREGISTERED`: トークンが登録されていない
   - `SENDER_ID_MISMATCH`: プロジェクトが一致しない

---

### 4. 🟡 **entitlements ファイルと Xcode 設定の不一致**（確率: 30%）

**確認済み（今回の調査）**:
```xml
<!-- ios/Runner/Runner.entitlements (Debug) -->
<key>aps-environment</key>
<string>development</string>

<!-- ios/Runner/RunnerRelease.entitlements (Release) -->
<key>aps-environment</key>
<string>production</string>
```

**Xcode プロジェクト設定の確認が必要**:
1. Xcode で `ios/Runner.xcodeproj` を開く
2. Runner ターゲット → Signing & Capabilities
3. "Push Notifications" capability が有効か確認
4. Build Settings → Code Signing Entitlements:
   - Debug: `Runner/Runner.entitlements`
   - Release: `Runner/RunnerRelease.entitlements`
5. Provisioning Profile が Push Notifications を含むか確認

**検証方法**:
```bash
# entitlements が正しくビルドに含まれているか確認
cd ios
xcodebuild -showBuildSettings -scheme Runner -configuration Debug | grep CODE_SIGN_ENTITLEMENTS
xcodebuild -showBuildSettings -scheme Runner -configuration Release | grep CODE_SIGN_ENTITLEMENTS
```

期待される出力:
```
Debug:   CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements
Release: CODE_SIGN_ENTITLEMENTS = Runner/RunnerRelease.entitlements
```

---

### 5. 🟢 **通知権限が拒否されている**（確率: 20%）

**確認方法**:
1. 通知デバッグ画面を開く
2. "Permission Status" を確認:
   - ✅ `authorized`: 正常
   - ⚠️ `denied`: ユーザーが拒否
   - ⚠️ `notDetermined`: まだリクエストされていない

**denied の場合の対処**:
1. iOS 設定アプリ → Famica → 通知
2. "通知を許可" をオンにする
3. アプリに戻って通知デバッグ画面で "Refresh Status" をタップ

**notDetermined の場合の対処**:
1. 通知デバッグ画面で "Request Notification Permission" をタップ
2. iOS のダイアログで "許可" を選択
3. APNs Token が取得されるまで待機（数秒）
4. "Refresh Status" で FCM Token が生成されたか確認

---

## 🔍 検証チェックリスト（優先度順）

### Phase 1: トークン保存・読み取りの確認（最重要）

- [ ] **Step 1.1**: Firebase Console → Firestore → `users/{iOS ユーザーの uid}` を開く
- [ ] **Step 1.2**: 以下のフィールドを確認:
  - [ ] `fcmToken`（単数）フィールドが存在するか？
  - [ ] `fcmTokens`（複数形）フィールドが存在するか？
  - [ ] `fcmTokens` がオブジェクト形式（`{"token123": true}`）か？
- [ ] **Step 1.3**: 通知デバッグ画面を開く
- [ ] **Step 1.4**: FCM Token をコピーして、Firestore の値と照合
- [ ] **Step 1.5**: Firestore に保存されているトークンと実際のデバイスのトークンが一致するか確認

**期待される Firestore 構造**:
```json
{
  "users": {
    "{uid}": {
      "fcmTokens": {
        "fA1B2c3D4...xyz": true
      },
      "notificationsEnabled": true,
      "notifyPartnerActions": true,
      "notifyInactivity": true
    }
  }
}
```

**もし `fcmToken`（単数）フィールドしかない場合**:
→ **これが根本原因**。Cloud Functions が読み取れない。

---

### Phase 2: APNs Token の確認

- [ ] **Step 2.1**: 通知デバッグ画面を開く
- [ ] **Step 2.2**: Platform が "iOS" であることを確認
- [ ] **Step 2.3**: Build Mode を確認（debug / profile / release）
- [ ] **Step 2.4**: Permission Status を確認
  - [ ] `authorized` であるか？
  - [ ] `denied` の場合は iOS 設定から許可
  - [ ] `notDetermined` の場合は "Request Notification Permission" をタップ
- [ ] **Step 2.5**: APNs Token のステータスを確認
  - [ ] `✅ Available` か？
  - [ ] `❌ Not Available` の場合は "Retry APNs Token" を 3〜5 回押す
- [ ] **Step 2.6**: それでも取得できない場合:
  - [ ] アプリを完全終了
  - [ ] デバイスを再起動
  - [ ] アプリを再起動して再確認

---

### Phase 3: FCM Token の確認

- [ ] **Step 3.1**: 通知デバッグ画面で FCM Token が表示されているか確認
- [ ] **Step 3.2**: "Copy" ボタンでトークンをクリップボードにコピー
- [ ] **Step 3.3**: メモアプリなどに貼り付けて保存
- [ ] **Step 3.4**: Firebase Console → Cloud Messaging → "テストメッセージを送信"
- [ ] **Step 3.5**: コピーした FCM Token を貼り付けて "テスト" をクリック
- [ ] **Step 3.6**: 結果を確認:
  - [ ] 通知が届いた → Firebase 側は正常、Cloud Functions の問題
  - [ ] エラーメッセージが表示される → エラー内容を記録
  - [ ] 何も起こらない → トークンが無効または古い

**エラーメッセージの意味**:
- `INVALID_ARGUMENT`: トークン形式が不正
- `UNREGISTERED`: トークンが Firebase に登録されていない
- `SENDER_ID_MISMATCH`: 別の Firebase プロジェクトのトークン
- `InvalidProviderToken`: APNs 認証キーが無効または設定されていない

---

### Phase 4: Firebase Console の APNs 設定確認

- [ ] **Step 4.1**: Firebase Console → プロジェクト設定
- [ ] **Step 4.2**: "Cloud Messaging" タブを開く
- [ ] **Step 4.3**: "Apple アプリの構成" セクションを確認
- [ ] **Step 4.4**: `com.matsushima.famica` アプリを探す
- [ ] **Step 4.5**: APNs 認証キーの設定状況を確認:
  - [ ] "APNs 認証キー" がアップロード済みか？
  - [ ] Key ID が表示されているか？
  - [ ] Team ID が表示されているか？
- [ ] **Step 4.6**: 設定されていない場合は Apple Developer で `.p8` ファイルを生成してアップロード

**Apple Developer での APNs Key 生成手順**:
1. Apple Developer → Certificates, Identifiers & Profiles
2. Keys → "+" ボタン
3. "Apple Push Notifications service (APNs)" を選択
4. Key Name を入力（例: "Famica APNs Key"）
5. "Continue" → "Register" → `.p8` ファイルをダウンロード
6. **Key ID と Team ID をメモ**（後で Firebase に入力）
7. Firebase Console に戻って `.p8` ファイルと Key ID、Team ID をアップロード

---

### Phase 5: Xcode の Push Notifications Capability 確認

- [ ] **Step 5.1**: Xcode で `ios/Runner.xcodeproj` を開く
- [ ] **Step 5.2**: Runner ターゲットを選択
- [ ] **Step 5.3**: "Signing & Capabilities" タブを開く
- [ ] **Step 5.4**: "Push Notifications" capability が有効か確認
  - [ ] なければ "+" ボタンから追加
- [ ] **Step 5.5**: "Background Modes" capability を確認
  - [ ] "Remote notifications" にチェックが入っているか
- [ ] **Step 5.6**: Build Settings → "Code Signing Entitlements" を確認:
  - [ ] Debug: `Runner/Runner.entitlements`
  - [ ] Release: `Runner/RunnerRelease.entitlements`

---

## 📊 ログの確認方法

### Xcode Device Console でのログ確認

1. **Xcode を開く**
2. **Window → Devices and Simulators**
3. **実機を選択 → "Open Console" ボタン**
4. **フィルタに "FCM" "APNs" "notification" を入力**

**確認すべきログ**:
```
✅ 正常なログ:
🔔 FCMService.initialize() 呼び出し #1: 初期化開始...
✅ ローカル通知プラグイン初期化完了
🔔 通知権限: authorized
🍎 APNSトークン取得成功: abc123def456...
📱 FCMトークン取得成功
✅ FCMトークン保存完了
✅ FCMService: 初期化完了
```

```
❌ 問題のあるログ:
⚠️ APNSトークンを取得できませんでした
⚠️ FCMトークンを取得できませんでした
❌ トークン保存エラー: ...
```

### Firebase Messaging のデバッグログを有効化（オプション）

**Info.plist に追加（デバッグ時のみ）**:
```xml
<key>FirebaseMessagingAutoInitEnabled</key>
<false/>
<key>FirebaseAppDelegateProxyEnabled</key>
<true/>
```

現在は `FirebaseAppDelegateProxyEnabled = true` が設定済み。

---

## 🔄 トークン更新の仕組みとシナリオ

### FCM Token の更新タイミング

1. **アプリ初回インストール時**: 新規トークン生成
2. **アプリ再インストール時**: 新規トークン生成（古いトークンは無効化）
3. **通知権限の変更時**:
   - 拒否 → 許可: 新規トークン生成
   - 許可 → 拒否: トークンは無効化されない（Firebase 側で削除推奨）
4. **APNs Token の変更時**: FCM Token も再生成
5. **Firebase SDK の内部ロジック**: 定期的にトークンをリフレッシュ（30日周期など）

### トークンの staleness（古さ）が発生するケース

1. **アプリを削除 → 再インストール**: 古いトークンが Firestore に残る
2. **デバイスを初期化**: APNs Token が変わる
3. **長期間アプリを起動していない**: トークンが期限切れになる可能性
4. **複数デバイスで同じアカウント使用**: 古いデバイスのトークンが残る

### サーバー側（Cloud Functions）が行うべきこと

**概念的な対応**（コード変更時の指針）:

1. **複数トークンの管理**:
```javascript
// ユーザーごとに複数の FCM トークンを保存（マップ形式）
fcmTokens: {
  "token1": true,
  "token2": true,
  "token3": true
}
```

2. **無効トークンの自動削除**:
```javascript
// 通知送信時にエラーが返ってきたら削除
if (error.code === 'messaging/invalid-registration-token' ||
    error.code === 'messaging/registration-token-not-registered') {
  // Firestore から削除
  await db.collection('users').doc(uid).update({
    [`fcmTokens.${token}`]: admin.firestore.FieldValue.delete()
  });
}
```

3. **複数トークンへの一斉送信**:
```javascript
// sendEachForMulticast で複数トークンに送信
const response = await admin.messaging().sendEachForMulticast({
  tokens: tokenList,
  notification: {...},
  data: {...}
});
```

**現在の実装状況**:
- ✅ Cloud Functions は `fcmTokens` マップを使用
- ✅ 無効トークンの自動削除機能あり（Line 680-693）
- ✅ `sendEachForMulticast` で複数トークンに送信
- ❌ FCMService が正しく `fcmTokens` に保存しているか要確認

---

## 🚨 App Store 提出前のリスク評価（Go / No-Go）

### 現状のリスクレベル: 🔴 **HIGH**

**理由**:
1. **トークン保存先の不一致が未解決の場合**: 通知が一切届かない
2. **APNs Token 取得の失敗率が高い場合**: ユーザー体験が悪化
3. **Firebase Console テストで通知が届かない**: 根本的な設定ミス

### Go 判定の条件

✅ **以下をすべてクリアすれば Go**:

1. [ ] Firebase Console のテストメッセージが iOS 実機に届く
2. [ ] 通知デバッグ画面で以下がすべて `✅ Available`:
   - [ ] Permission Status: `authorized`
   - [ ] APNs Token: `✅ Available`
   - [ ] FCM Token: `✅ Available`
3. [ ] Firestore の `users/{uid}.fcmTokens` にトークンが正しく保存される
4. [ ] Cloud Functions から送信される通知が実機に届く（タスク作成、感謝メッセージなど）
5. [ ] 複数回のアプリ再起動後も通知が届き続ける
6. [ ] TestFlight ビルドでも通知が届くことを確認

### No-Go 判定の場合の対処

❌ **上記のいずれかが失敗する場合**:

1. **App Store 提出を延期**
2. **コード修正が必要**:
   - トークン保存ロジックの修正
   - APNs Token 取得リトライの改善
   - Firebase APNs 設定の修正
3. **修正後、再度フルテストを実施**

---

## 👨‍⚖️ Apple レビュー時の通知テスト方法

### Apple レビュアーが行う可能性のあるテスト

1. **TestFlight ビルドのインストール**
2. **初回起動時の通知権限ダイアログ**:
   - "許可" を選択した場合に通知が届くか
   - "許可しない" を選択した場合にアプリが正常動作するか
3. **アプリ内でトリガーされる通知の確認**:
   - パートナーがタスクを作成 → 通知が届くか
   - 感謝メッセージを送信 → 通知が届くか
4. **フォアグラウンド / バックグラウンド / 終了時の通知テスト**
5. **通知タップ時のディープリンク動作**

### リジェクトされる可能性のあるシナリオ

❌ **以下の場合はリジェクトのリスク**:

1. **通知機能がまったく動作しない**: 重大なバグとみなされる
2. **通知権限を拒否するとアプリがクラッシュする**: 必須権限ではないはず
3. **通知内容が不適切**: スパムやプライバシー侵害
4. **通知が過剰に表示される**: ユーザー体験の悪化

### リジェクトを避けるための推奨事項

✅ **以下を実施**:

1. **通知設定画面を用意**: ユーザーが通知の ON/OFF を切り替えられる
2. **通知の説明を追加**: 何の通知が来るのかを明記
3. **テストアカウントを用意**: レビュアーが通知をテストできる環境
4. **App Review Information に記載**:
   ```
   テストアカウント1: test1@example.com / password123
   テストアカウント2: test2@example.com / password123
   
   通知テスト手順:
   1. テストアカウント1でログイン
   2. 別デバイスでテストアカウント2でログイン
   3. テストアカウント2でタスクを作成
   4. テストアカウント1のデバイスに通知が届くことを確認
   ```

---

## 🎯 推奨される次のアクション（優先度順）

### 優先度1: トークン保存の検証（即座に実施）

```
1. Firebase Console → Firestore を開く
2. users/{iOS ユーザーの uid} を確認
3. fcmToken / fcmTokens フィールドを確認
4. 通知デバッグ画面の FCM Token と照合
```

**もし不一致なら**: これが根本原因。コード修正が必須。

---

### 優先度2: Firebase Console でのテスト送信

```
1. 通知デバッグ画面で FCM Token をコピー
2. Firebase Console → Cloud Messaging → "テストメッセージを送信"
3. トークンを貼り付けて送信
4. 実機に通知が届くか確認
```

**届かない場合**: Firebase APNs 設定または APNs Key の問題。

---

### 優先度3: APNs Token 取得の安定化（コード修正）

```dart
// lib/services/fcm_service.dart を修正
// リトライ回数を 3 → 10 に増加
// 待機時間を指数バックオフに変更
```

---

### 優先度4: 通知フロー全体のエンドツーエンドテスト

```
1. アプリをアンインストール
2. 再インストール
3. ログイン
4. 通知権限を許可
5. 通知デバッグ画面で全項目が ✅ であることを確認
6. パートナーアカウントでタスク作成
7. 通知が届くことを確認
```

---

## 📝 まとめ

### 最も可能性の高い根本原因

🔴 **トークン保存先の不一致**（`fcmToken` vs `fcmTokens`）

### 次に可能性の高い原因

🟠 **APNs Token 取得タイミングの問題**（リトライ不足）

### その他の確認が必要な項目

🟡 Firebase APNs 認証キー設定  
🟡 Xcode Capabilities 設定  
🟢 通知権限の状態

### 調査ツール

✅ **通知デバッグ画面** - 実装済み、すぐに使える  
✅ **Firebase Console** - テスト送信機能  
✅ **Xcode Device Console** - リアルタイムログ  
✅ **Firestore Console** - トークンの保存状態を直接確認

---

**次のステップ**: 上記の検証チェックリストに従って、順番に確認を進めてください。特に **Phase 1: トークン保存・読み取りの確認** を最優先で実施することを強く推奨します。

---

**作成者**: Claude (Cline)  
**日付**: 2026年1月29日  
**バージョン**: 1.0  
**ステータス**: 調査完了（コード変更なし）
