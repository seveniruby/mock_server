<?PHP
$tcs=array();
$tc=array();
foreach(file($argv[1]) as $content){
	$data=explode(' ',$content);
	$key=$data[0];
	$value=rtrim($data[1]);
	if($value=="start"){
		$tc=array();
		continue;
	}
	if($value=="end"){
		$tcs[]=$tc;
		continue;
	}
	//$data=base64_decode($hex[1]);
	$value=pack('H*',$value);
	$value=mc_pack_pack2array(substr($value,36));
	if($key=="request"){
		$tc[]= array('req'=>json_encode($value));
	}else{
		$tc[]= array( 'res'=>json_encode($value));
	}
}
var_dump($tcs);
