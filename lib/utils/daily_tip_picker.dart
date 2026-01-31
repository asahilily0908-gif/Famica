/// 日替わりヒント選択ロジック
/// UTC日付ベースで決定論的にヒントを選択（全ユーザー同じヒント）

import '../data/daily_tips.dart';

/// 今日のヒントを取得
/// 
/// UTC日付を基準に、2024年1月1日からの経過日数で決定
/// 全ユーザーが同じ日に同じヒントを見る
DailyTip getTodayTip() {
  final now = DateTime.now().toUtc();
  final epoch = DateTime.utc(2024, 1, 1);
  
  // 2024/1/1からの経過日数を計算
  final daysSinceEpoch = now.difference(epoch).inDays;
  
  // ヒント配列のインデックスを決定（循環）
  final index = daysSinceEpoch % dailyTips.length;
  
  return dailyTips[index];
}
