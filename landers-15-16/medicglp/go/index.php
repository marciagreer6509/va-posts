<?php
// /go/ redirect for MedicGLP. The tracking link lives ONLY in this file (never in the page).
$LINK = 'https://www.slmw4qtrk.com/ZZ2GX/TZW7X1/?sub1=medicglpukgads&sub2=gadspop';
$MAX_PER_HOUR = 4;
$home = rtrim(dirname(dirname($_SERVER['SCRIPT_NAME'])), '/') . '/';
header('Cache-Control: no-store');
header('X-Robots-Tag: noindex, nofollow');
function back($to) { header('Location: ' . $to, true, 302); exit; }
$ua = isset($_SERVER['HTTP_USER_AGENT']) ? $_SERVER['HTTP_USER_AGENT'] : '';
$googleBot = preg_match('/AdsBot-Google|Googlebot|Google-Ads|Mediapartners-Google|Google-InspectionTool/i', $ua);
if (!$googleBot) {
  if ($ua === '' || preg_match('/curl|wget|python|httpclient|okhttp|go-http|java\/|headless|phantom|scrapy|semrush|ahrefs|mj12|dotbot|petalbot|bytespider|bot\b|crawler|spider/i', $ua)) back($home);
  $ip = isset($_SERVER['HTTP_CF_CONNECTING_IP']) ? $_SERVER['HTTP_CF_CONNECTING_IP'] : $_SERVER['REMOTE_ADDR'];
  $f = sys_get_temp_dir() . '/medicglpgo_' . md5($ip);
  $hits = [];
  if (is_file($f)) { $hits = array_filter(explode(',', (string)@file_get_contents($f)), function ($t) { return $t > time() - 3600; }); }
  $hits[] = time();
  @file_put_contents($f, implode(',', $hits), LOCK_EX);
  if (count($hits) > $MAX_PER_HOUR) back($home);
}
$dest = $LINK;
$cid = isset($_GET['cid']) ? substr(preg_replace('/[^\w.\-:]/', '', $_GET['cid']), 0, 200) : '';
if ($cid !== '') $dest .= '&sub3=' . rawurlencode($cid);
header('Referrer-Policy: no-referrer');
back($dest);
