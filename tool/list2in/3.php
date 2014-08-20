<?php 
	$message= $_POST['test'];
	$result= explode("\n", $message);
	echo $_POST['sql'];
	$finalResult= "";
	foreach ($result as $key => $value) {
		$finalResult.= '\''.trim($value).'\',';
	}
	$finalResult= substr($finalResult, 0, -1);
	$finalResult='('.$finalResult.');';
	echo $finalResult;


?>