<?PHP


function pretty_json($json) {
	$result      = '';
	$pos         = 0;
	$strLen      = strlen($json);
	$indentStr   = '  ';
	$newLine     = "\n";
	$prevChar    = '';
	$outOfQuotes = true;

	for ($i=0; $i<=$strLen; $i++) {

		// Grab the next character in the string.
		$char = substr($json, $i, 1);

		// Are we inside a quoted string?
		if ($char == '"' && $prevChar != '\\') {
			$outOfQuotes = !$outOfQuotes;

			// If this character is the end of an element, 
			// output a new line and indent the next line.
		} else if(($char == '}' || $char == ']') && $outOfQuotes) {
			$result .= $newLine;
			$pos --;
			for ($j=0; $j<$pos; $j++) {
				$result .= $indentStr;
			}
		}

		// Add the character to the result string.
		$result .= $char;

		// If the last character was the beginning of an element, 
		// output a new line and indent the next line.
		if (($char == ',' || $char == '{' || $char == '[') && $outOfQuotes) {
			$result .= $newLine;
			if ($char == '{' || $char == '[') {
				$pos ++;
			}

			for ($j = 0; $j < $pos; $j++) {
				$result .= $indentStr;
			}
		}

		$prevChar = $char;
	}

	return $result;
}



function parse($file){
	$content=json_decode(file_get_contents($file),true);
	$datas_new=array();
	foreach($content as $data){
		foreach($data as $k=>$v){
			$v=base64_decode($v);
			$v=mc_pack_pack2array(substr($v,36));
			$data_new=array($k=>$v);
			$datas_new[]=$data_new;
		}

	}
	$datas_new=json_encode($datas_new);
	return $datas_new;
}
print_r(pretty_json(parse("proxy.log.base64json")));


//$data = ral ( 'dbgate', 'queryUIDByMobile', $req ,rand());
