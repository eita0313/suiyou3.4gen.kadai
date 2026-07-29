<?php
// アクセスカウント用のキー名
$key = 'access_count';

// APCuから値を取得。なければ 0 をセット
$count = apcu_fetch($key);
if ($count === false) {
    $count = 0;
}

// カウントを増やして保存
$count++;
apcu_store($key, $count);

echo "<h1>現在のアクセス数 (揮発性): " . $count . "</h1>";
echo "<p>ページをリロードするとカウントが増えます。</p>";
echo "<p>Dockerコンテナを再起動（docker compose restart）するとカウントは0に戻ります。</p>";
?>
