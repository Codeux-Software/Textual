#!/usr/bin/php
<?php
	/* The function guid() shown below is borrowed from the Stack Overflow comment
	located at the address: <http://stackoverflow.com/a/15874518> — as no license
	is specified at the above URL, it is assumed to be released into the Public Domain. */
	
	function guid()
	{
	    $randomString = openssl_random_pseudo_bytes(16);
	    
	    $time_low = bin2hex(substr($randomString, 0, 4));
	    $time_mid = bin2hex(substr($randomString, 4, 2));
	    $time_hi_and_version = bin2hex(substr($randomString, 6, 2));
	    $clock_seq_hi_and_reserved = bin2hex(substr($randomString, 8, 2));
	    
	    $node = bin2hex(substr($randomString, 10, 6));
	
	    /**
	     * Set the four most significant bits (bits 12 through 15) of the
	     * time_hi_and_version field to the 4-bit version number from
	     * Section 4.1.3.
	     * @see http://tools.ietf.org/html/rfc4122#section-4.1.3
	    */
	    $time_hi_and_version = hexdec($time_hi_and_version);
	    $time_hi_and_version = $time_hi_and_version >> 4;
	    $time_hi_and_version = $time_hi_and_version | 0x4000;
	
	    /**
	     * Set the two most significant bits (bits 6 and 7) of the
	     * clock_seq_hi_and_reserved to zero and one, respectively.
	     */
	    $clock_seq_hi_and_reserved = hexdec($clock_seq_hi_and_reserved);
	    $clock_seq_hi_and_reserved = $clock_seq_hi_and_reserved >> 2;
	    $clock_seq_hi_and_reserved = $clock_seq_hi_and_reserved | 0x8000;
	
	    return sprintf('%08s-%04s-%04x-%04x-%012s', $time_low, $time_mid, $time_hi_and_version, $clock_seq_hi_and_reserved, $node);
	} // guid

	$inputInformation = trim($GLOBALS['argv'][2]);
	$destinationChannel = trim($GLOBALS['argv'][1]);
	
	$uuidCount = 1;
	
	if (empty($inputInformation) == false) {
		if (is_numeric($inputInformation) == false) {
			echo "/debug Invalid input. Proper syntax: /uuid [number]";
			
			exit();
		} else {
			$uuidCount = $inputInformation;
		}
	}
	
	if ($uuidCount <= 0) {
		echo "/debug Invalid input. Proper syntax: /uuid [number]";
			
		exit();
	}
	
	$resultString = "";
	
	for ($i = 0; $i < $uuidCount; $i++) {
		$uuidnum = ($i + 1);
		
		$resultString .= ("/debug UUID #{$uuidnum}: " . strtoupper(guid()) . "\n");
	}
	
	echo $resultString;
	
	exit();

?>