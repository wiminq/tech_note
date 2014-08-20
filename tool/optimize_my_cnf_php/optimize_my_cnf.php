<?php 
	$result='#prompt="(\u:HOSTNAME:)[\d]> "';
	$result.= 'port	= '.$_POST['port']."\n";
	$result.=$_POST['basedir'];
	// echo $result;
	file_put_contents("test.txt",$result);
?>