# 🚀 Famica リリース前チェックリスト

## 📅 作成日時
2025年10月30日

---

## ✅ 実装完了項目

### コア機能
- [x] ユーザー認証（Firebase Authentication）
- [x] 記録機能（クイック記録）
- [x] 感謝機能（💗ボタン）
- [x] 月次サマリー（円グラフ）
- [x] 記録一覧表示
- [x] 設定画面
- [x] 家族招待機能

### Plus機能（課金）
- [x] 課金システム（in_app_purchase）
- [x] Plus会員判定
- [x] ペイウォール画面
- [x] AI提案機能
- [x] 6ヶ月推移グラフ
- [x] 7日間トライアル

### データ管理
- [x] Firestore統合
- [x] households構造
- [x] カスタムカテゴリ
- [x] 感謝バッジシステム
- [x] インサイト自動生成

### UI/UX
- [x] ボトムナビゲーション
- [x] Famica配色適用
- [x] レスポンシブデザイン
- [x] ローディング状態
- [x] エラーハンドリング

---

## 🔧 リリース前に必要な作業

### 1. ⚠️ 重要：課金設定（Apple/Google）

#### iOS App Store Connect
```
[ ] App Store Connectにアプリ登録
[ ] App内課金商品登録
    - famica_plus_monthly (¥480/月)
    - famica_plus_yearly (¥4,800/年)
[ ] 銀行口座情報登録
[ ] 税務情報登録
[ ] 契約・税金・口座情報 完了
```

#### Google Play Console
```
[ ] Play Consoleにアプリ登録
[ ] アプリ内商品登録
    - famica_plus_monthly (¥480/月)
    - famica_plus_yearly (¥4,800/年)
[ ] お支払いプロファイル設定
[ ] 銀行口座情報登録
```

### 2. 📱 アプリ設定確認

#### pubspec.yaml
```yaml
[ ] version: 1.0.0+1 確認
[ ] name: famica 確認
[ ] description: カップル・夫婦向け家事記録アプリ
```

#### iOS (Info.plist)
```
[x] Bundle Identifier: com.matsushima.famica
[x] Version: 1.0.0
[x] Build: 1
[x] Display Name: Famica
[x] 通知権限説明文
[ ] アプリアイコン（1024x1024）
[ ] Launch Screen
```

#### Android (build.gradle.kts)
```
[x] applicationId: com.matsushima.famica
[x] versionName: 1.0.0
[x] versionCode: 1
[ ] アプリアイコン
[ ] Splash Screen
```

### 3. 🔐 セキュリティ・プライバシー

```
[x] Firestore Rules設定
[x] 環境変数管理（Firebase設定）
[ ] プライバシーポリシー作成
[ ] 利用規約作成
[ ] App Privacy（データ収集内容）記載
```

#### プライバシーポリシー必須項目
```
[ ] 収集するデータ
    - メールアドレス
    - 記録データ（家事・育児）
    - 感謝メッセージ
[ ] データの使用目的
[ ] データの保存場所（Firebase）
[ ] データの削除方法
[ ] 第三者提供の有無
[ ] お問い合わせ先
```

### 4. 📸 ストア素材

#### スクリーンショット（各5枚）
```
[ ] iPhone 6.5インチ（1242x2688）
    - ホーム画面
    - クイック記録
    - 円グラフ
    - 6ヶ月グラフ（Plus）
    - 感謝画面

[ ] Android（1080x1920）
    - 同上
```

#### アイコン
```
[ ] iOS App Icon（1024x1024）
[ ] Android Launcher Icon
[ ] Play Store Feature Graphic（1024x500）
```

#### 紹介動画（任意）
```
[ ] 30秒プレビュー動画
```

### 5. ストア情報

#### 共通
```
[ ] アプリ名: Famica
[ ] サブタイトル: ふたりのがんばりを10秒で記録
[ ] カテゴリ: ライフスタイル
[ ] 対象年齢: 4+（全年齢）
[ ] アプリ説明文（日本語）
[ ] キーワード
    - 家事記録, カップル, 夫婦, 感謝, 家事分担
```

#### App Store固有
```
[ ] プロモーション用テキスト
[ ] サポートURL
[ ] マーケティングURL
```

#### Play Store固有
```
[ ] 短い説明文（80文字）
[ ] 完全な説明文（4000文字）
```

### 6. 🧪 テスト

#### 機能テスト
```
[x] 新規登録フロー
[x] ログインフロー
[x] 記録作成
[x] 感謝送信
[x] Plus会員判定
[x] ペイウォール表示
[ ] 課金フロー（Sandbox）
    - 月額購入
    - 年額購入
    - 購入復元
[ ] トライアル開始
[ ] トライアル終了後の動作
```

#### デバイステスト
```
[ ] iPhone（iOS 14+）
[ ] iPad（任意）
[ ] Android（API 21+）
[ ] タブレット（任意）
```

#### エッジケース
```
[x] オフライン時の動作
[x] ネットワークエラー
[x] Firestore権限エラー
[ ] 課金エラー時の処理
[ ] 既存ユーザーのデータ移行
```

### 7. Cloud Functions（任意）

```
[ ] トライアル期限チェック（日次バッチ）
[ ] 購入確認Webhook
[ ] メール通知設定
```

### 8. 分析・モニタリング

```
[x] Firebase Analytics設定
[ ] Crashlytics設定
[ ] Performance Monitoring
```

---

## 📋 リリース手順

### Phase 1: 内部テスト（今ここ）
```
[ ] TestFlight（iOS）アップロード
[ ] Play Console内部テスト アップロード
[ ] 内部テスターで動作確認
    - 基本機能
    - 課金フロー
    - エラーハンドリング
```

### Phase 2: 外部テスト（任意）
```
[ ] TestFlight外部テスト（最大10,000人）
[ ] Play Console クローズドテスト
[ ] フィードバック収集
[ ] バグ修正
```

### Phase 3: 本番リリース
```
[ ] App Store審査提出
    - 通常2-3日
    - リジェクト時の対応準備
[ ] Play Store審査提出
    - 通常数時間～1日
[ ] 審査承認待ち
```

### Phase 4: リリース後
```
[ ] クラッシュレポート監視
[ ] ユーザーレビュー確認
[ ] バグ修正アップデート
[ ] 機能改善
```

---

## ⚠️ リリース前の最重要事項

### 1. 課金設定（最優先）
- App Store Connect / Play Console で商品登録
- **これがないと課金機能が動作しません**

### 2. プライバシーポリシー
- App Store審査で必須
- Webサイトまたは設定画面内に配置

### 3. 利用規約
- 課金アプリは必須
- 特定商取引法に基づく表記

### 4. スクリーンショット
- ストア掲載に必須
- 実機で撮影または Simulator/Emulator

### 5. テスト用課金
- **Sandbox環境でテスト必須**
- Apple: Sandbox Tester登録
- Google: テストライセンス設定

---

## 📝 次のステップ

### すぐにやること
1. **課金商品登録**（Apple & Google）
2. **プライバシーポリシー作成**
3. **スクリーンショット準備**
4. **Sandbox課金テスト**

### その後
5. TestFlightアップロード
6. Play Console内部テスト
7. 内部テスターでテスト
8. フィードバック対応
9. 本番リリース申請

---

## 🎯 リリース目標

### Short Term（1-2週間）
- 内部テスト開始
- 課金フロー完全テスト
- バグ修正

### Mid Term（2-4週間）
- 外部テスト（任意）
- ストア審査提出
- 本番リリース

### Long Term（1-3ヶ月）
- ユーザーフィードバック収集
- 機能改善
- マーケティング

---

## 📞 サポート

### Apple
- https://developer.apple.com/support/
- App Store Connect Help

### Google
- https://support.google.com/googleplay/android-developer/
- Play Console Help

---

**最終更新**: 2025年10月30日
