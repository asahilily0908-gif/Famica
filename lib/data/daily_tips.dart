/// 日替わりのヒントデータ
/// カテゴリ別の生活のヒント50個をハードコード

class DailyTip {
  final String category;
  final String body;

  const DailyTip({
    required this.category,
    required this.body,
  });
}

/// 50個の日替わりヒント（カテゴリ: キッチン / お部屋 / 衣類）
const List<DailyTip> dailyTips = [
  // キッチン (1-20)
  DailyTip(
    category: 'キッチン',
    body: 'レンジの汚れ：コップ1杯のレモン水や重曹水を5分加熱。蒸気で汚れがふやけて、拭き掃除が楽になりますよ。',
  ),
  DailyTip(
    category: 'キッチン',
    body: '鍋の焦げ付き：重曹と水を入れて沸騰させ、冷めるまで放置。無理にこすらず、するんと落としてみましょう。',
  ),
  DailyTip(
    category: 'キッチン',
    body: '排水口のヌメリ：アルミホイルを丸めて入れるだけ。金属の力で、嫌なヌメリをそっと防いでくれます。',
  ),
  DailyTip(
    category: 'キッチン',
    body: 'グリルの後片付け：水に片栗粉を混ぜておくと、使用後は固まった膜を剥がすだけ。お掃除がぐんと身近になります。',
  ),
  DailyTip(
    category: 'キッチン',
    body: 'まな板のケア：塩を振ってレモンの切り口でこすってみて。自然の力で、消臭と除菌が同時に叶います。',
  ),
  DailyTip(
    category: 'キッチン',
    body: '換気扇の油：掃除の前にドライヤーで温めてみて。油がゆるんで、驚くほど素直に落ちてくれます。',
  ),
  DailyTip(
    category: 'キッチン',
    body: 'ジャガイモの保存：リンゴを1つ一緒に入れてあげて。エチレンガスの効果で、芽が出るのを遅らせてくれます。',
  ),
  DailyTip(
    category: 'キッチン',
    body: '固まった砂糖：湿らせたキッチンペーパーを容器に数分。少しの潤いで、またサラサラに戻りますよ。',
  ),
  DailyTip(
    category: 'キッチン',
    body: '蛇口の曇り：お料理で使ったジャガイモの皮で磨いてみて。捨てる前のひと手間で、キラリと輝きます。',
  ),
  DailyTip(
    category: 'キッチン',
    body: 'タッパーの匂い：塩水を入れて振るか、お日様に当ててみて。匂いが消えて、また気持ちよく使えます。',
  ),
  DailyTip(
    category: 'キッチン',
    body: 'バナナを長持ち：根元の部分をラップで包んでみて。これだけで、黒くなるのを少し遅らせてくれます。',
  ),
  DailyTip(
    category: 'キッチン',
    body: 'ニンニクの皮むき：レンジで10秒ほど加熱してみて。薄皮が浮いて、指でつるんと簡単にむけます。',
  ),
  DailyTip(
    category: 'キッチン',
    body: '玉ねぎで涙：切る前に15分ほど冷蔵庫で冷やしてみて。刺激成分が抑えられます。',
  ),
  DailyTip(
    category: 'キッチン',
    body: '瓶の汚れ：砕いた卵の殻と水を入れて振ってみて。隅まで綺麗に洗えます。',
  ),
  DailyTip(
    category: 'キッチン',
    body: '卵の鮮度チェック：水に入れて沈めば新鮮。浮いたら早めに使ってあげてください。',
  ),
  DailyTip(
    category: 'キッチン',
    body: 'コーヒーのカス：乾燥させて冷蔵庫へ。天然の消臭剤になります。',
  ),
  DailyTip(
    category: 'キッチン',
    body: 'ハチミツの結晶：40〜50度のお湯で湯煎。栄養を壊さず戻せます。',
  ),
  DailyTip(
    category: 'キッチン',
    body: 'お米の虫除け：唐辛子を1本、米びつに入れてみて。',
  ),
  DailyTip(
    category: 'キッチン',
    body: 'コンロ周りの油：みかんの皮で拭いてみて。皮の油分が汚れをゆるめます。',
  ),
  DailyTip(
    category: 'キッチン',
    body: '野菜の復活：冷水に少量の砂糖とレモン汁。シャキッと戻ります。',
  ),
  
  // お部屋 (21-40)
  DailyTip(
    category: 'お部屋',
    body: '窓の掃除：濡らした新聞紙で拭くと、汚れがつきにくくなります。',
  ),
  DailyTip(
    category: 'お部屋',
    body: '家具のホコリ：柔軟剤を少し混ぜた水で拭くと静電気防止に。',
  ),
  DailyTip(
    category: 'お部屋',
    body: 'カーペットの毛：ゴム手袋でなでるだけ。',
  ),
  DailyTip(
    category: 'お部屋',
    body: 'シール跡：ハンドクリームをなじませて優しく剥がします。',
  ),
  DailyTip(
    category: 'お部屋',
    body: '鏡の曇り止め：石鹸を塗って乾拭き。',
  ),
  DailyTip(
    category: 'お部屋',
    body: 'シャワーの目詰まり：お酢入りのお湯でつけ置き。',
  ),
  DailyTip(
    category: 'お部屋',
    body: '水垢：歯磨き粉をつけた古歯ブラシで。',
  ),
  DailyTip(
    category: 'お部屋',
    body: 'ブラインド：軍手で挟んで一拭き。',
  ),
  DailyTip(
    category: 'お部屋',
    body: 'フローリングの溝：輪ゴムを巻いた芯でコロコロ。',
  ),
  DailyTip(
    category: 'お部屋',
    body: '高い場所：ストッキング付きハンガーでホコリ取り。',
  ),
  DailyTip(
    category: 'お部屋',
    body: 'スマホ画面：コーヒーフィルターで拭く。',
  ),
  DailyTip(
    category: 'お部屋',
    body: '壁の落書き：歯磨き粉で円を描くように。',
  ),
  DailyTip(
    category: 'お部屋',
    body: '花瓶のヌメリ：10円玉を1枚入れる。',
  ),
  DailyTip(
    category: 'お部屋',
    body: '掃除機の匂い：重曹を吸わせる。',
  ),
  DailyTip(
    category: 'お部屋',
    body: '排水口の匂い：寝る前に氷を数個。',
  ),
  DailyTip(
    category: 'お部屋',
    body: '玄関掃除：濡らした新聞紙を撒いてから掃く。',
  ),
  DailyTip(
    category: 'お部屋',
    body: 'カーペットの凹み：氷を置いて戻す。',
  ),
  DailyTip(
    category: 'お部屋',
    body: 'ガラス片：食パンで押さえる。',
  ),
  DailyTip(
    category: 'お部屋',
    body: 'テレビ画面：乾いたマイクロファイバーで。',
  ),
  DailyTip(
    category: 'お部屋',
    body: '部屋の香り：香水を含ませたコットンをフィルターへ。',
  ),
  
  // 衣類 (41-50)
  DailyTip(
    category: '衣類',
    body: '乾燥を時短：乾燥機に乾いたバスタオル1枚。',
  ),
  DailyTip(
    category: '衣類',
    body: '軽いシワ：入浴後の浴室に吊るす。',
  ),
  DailyTip(
    category: '衣類',
    body: '靴の消臭：茶葉やティーバッグを入れる。',
  ),
  DailyTip(
    category: '衣類',
    body: 'ボタン保護：糸に透明マニキュア。',
  ),
  DailyTip(
    category: '衣類',
    body: 'タオル復活：干す前に10回振る。',
  ),
  DailyTip(
    category: '衣類',
    body: '襟汚れ：洗う前にシェービングフォーム。',
  ),
  DailyTip(
    category: '衣類',
    body: '生乾き臭：50度のお湯＋酸素系漂白剤。',
  ),
  DailyTip(
    category: '衣類',
    body: 'アイロン時短：アルミホイルを下に。',
  ),
  DailyTip(
    category: '衣類',
    body: 'クローゼット湿気：重曹を小瓶に。',
  ),
  DailyTip(
    category: '衣類',
    body: '洗濯槽のニオイ：月1回、酸素系漂白剤でつけ置き。見えない汚れが落ちます。',
  ),
];
