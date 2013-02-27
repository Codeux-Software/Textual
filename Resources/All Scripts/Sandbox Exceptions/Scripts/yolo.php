#!/usr/bin/php
<?php

	/*
		 Portions of this PHP Script may incorporate work from 3rd
		 parties. These portions of code are noted. All other work is
		 Copyright © 2010 — 2013 Codeux Software. See README
		 for full license information.
	 */

	/* There is no real reason this in PHP other than to
	 test the ability of Textual to execute something other
	 than AppleScript. It is packaged as an example. */

	error_reporting(E_NONE);

	/* Valid calendars. */

	$calendarTypes = array("birthday" => "Famous Birthday",
						   "computer" => "Computer History",
						   "history" => "History",
						   "holiday" => "Holiday",
						   "freebsd" => "FreeBSD Developer Birthday",
						   "music" => "Music History",
	/* dafuq FreeBSD? */   "lotr" => "Lord of the Rings");

	/* *********************************************************** */

	/* Is the calendar requested valid? */

	$calendarVerbose = trim($GLOBALS['argv'][1]);
	$calendarIsVerbose = false;
	
	if ($calendarVerbose == "-v") {
		$calendarIsVerbose = true;
		
		$calendarKey = trim($GLOBALS['argv'][2]);
	} else {
		$calendarKey = $calendarVerbose;
	}

	$calendarTitle = $calendarTypes[$calendarKey];

	if (empty($calendarTitle)) {
		echo "/debug Syntax: /yolo [-v] <calendar>\n/debug Valid Calendars: birthday computer freebsd history holiday lotr music";

		exit();
	}

	/* *********************************************************** */

	/* Generate the date that will be matched against
	 the calendar entries. */

	$currentDate = date("m/d");
	//$currentDate = "02/01";
	
	/* *********************************************************** */

	/* Get the calander. */

	$calendar = file_get_contents("/usr/share/calendar/calendar.{$calendarKey}");

	if (empty($calendar)) {
		echo "/debug Failed to load calendar. Oops!";

		exit();
	}

	$calendarItemsOld = explode("\n", $calendar);
	$calendarItemsNew = array();

	/* Scan the calander. */

	for ($i = 0; $i < count($calendarItemsOld); $i++) {
		$citem = $calendarItemsOld[$i];

		/* Look for a tab with a specific position to indicate
		 a new dated calendar entry. */

		if (strpos($citem, "	") == 5) {
			/* Process next entry. */

			$citemParts = explode("	", $citem);

			$date = $citemParts[0];
			$text = $citemParts[1];

			if ($date == $currentDate && strlen($date) == 5) {
				/* Valid entry found. */

				$newItemTempStore = $citemParts[1];

				/* We will now scan the array ahead a few times
				 to see if this is a multi-line entry. */

				for ($d = ($i + 1); $d < ($i + 5); $d++) {
					$ocitem = $calendarItemsOld[$d];

					if (strpos($citem, "	") == 5) { // Break for dated entry.
						break;
					}

					if (strpos($ocitem, "	") == 0) {
						$ocitem = substr($ocitem, 1);

						$newItemTempStore = "{$newItemTempStore} {$ocitem}";
					}
				}

				/* Add entry. */

				$calendarItemsNew[] = $newItemTempStore;
			}
		}
	}

	/* *********************************************************** */

	/* The calendar was scanned and we now have all entries for today. */

	$entryCount = count($calendarItemsNew);

	if ($entryCount <= 0) {
		echo "/me does not see any entries in the \002{$calendarTitle}\002 calendar for today.";
	} else {
		if ($entryCount == 1) {
			if ($calendarIsVerbose == true) {
				echo "There is one entry in the \002{$calendarTitle}\002 calendar for today:\n\0021:\002 {$calendarItemsNew[0]}";
			} else {
				echo "There is one entry in the \002{$calendarTitle}\002 calendar for today: {$calendarItemsNew[0]}";
			}
		} else if ($entryCount == 2) {
			if ($calendarIsVerbose == true) {
				echo "There are two entries in the \002{$calendarTitle}\002 calendar for today:\n\0021:\002 {$calendarItemsNew[0]};\n\0022:\002 {$calendarItemsNew[1]};";
			} else {
				echo "There are two entries in the \002{$calendarTitle}\002 calendar for today: \0021:\002 {$calendarItemsNew[0]}; — \0022:\002 {$calendarItemsNew[1]};";
			}
		} else {
			$resultString = "There are {$entryCount} entries in the \002{$calendarTitle}\002 calendar for today:";

			if ($calendarIsVerbose == true) {
				$resultPrepend = "\n";
			} else {
				$resultAppend = " — ";
				$resultPrepend = " ";
			}
			
			for ($i = 0; $i < $entryCount; $i++) {
				$c = ($i + 1);

				if ($c == $entryCount) {
					$resultString .= "{$resultPrepend}\002{$c}:\002 {$calendarItemsNew[$i]};";
				} else {
					$resultString .= "{$resultPrepend}\002{$c}:\002 {$calendarItemsNew[$i]};{$resultAppend}";
				}
			}

			echo $resultString;
		}
	}
	
	/* *********************************************************** */
	
	exit();
	
?>