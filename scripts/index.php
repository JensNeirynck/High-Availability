<html>
<head>
<title>
<?php
echo gethostname();
?>
</title>
</head>
<body>
<h3>Databasetest</h3>
<p>
<?php
$dbname = 'drupal_db';
$dbuser = 'drupal_user';
$dbpass = 'drupalha';
$dbhost = '192.168.1.4';
$connect = mysql_connect($dbhost, $dbuser, $dbpass) or die("Unable to Connect to '$dbhost'");
mysql_select_db($dbname) or die("Could not open the db '$dbname'");
$test_query = "SHOW TABLES FROM $dbname";
$result = mysql_query($test_query);
$tblCnt = 0;
while($tbl = mysql_fetch_array($result)) {
  $tblCnt++;
}
if (!$tblCnt) {
  echo "Connection works, there are no tables \n";
} else {
  echo "Connection works, there are $tblCnt tables \n";
}
?>
</p>
</body>
</html>
##/var/www/html/index.php
