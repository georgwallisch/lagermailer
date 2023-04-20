#!/usr/bin/php
<?php

	$csvpath = '/mnt/Apo/4549705/export';
	$csvs = array('Antibiotika-Säfte' => 'ab_saefte_lager.csv', 'Antibiotika (Tabletten)' => 'ab_fest_lager.csv', 'Fiebersäfte' => 'fiebersaefte_lager.csv' /*, 'Fieberzäpfchen' => 'fieberzaepfchen_lager.csv'*/);
	$csv_separator = ';';
	$csv_encoding = 'Windows-1252';
	$db_encoding = 'UTF-8';
	$templatefile = dirname(__FILE__).'/body-template.html';
	$yieldtoken = '###YIELD###';
		
	$fields = array('Artikelname', 'PZN', 'DF', /*'PM', 'PE', */ 'Pck', 'N',/* 'Hersteller', */ 'Bestand', 'ABDA-WGR'); 
	
	$filter = array('N' => array('s' => 'kA, keine Angabe', 'r' => '--'));
	
	require_once 'bootstrap.php';
	
	// $bootstrap_config['inline'] = true;

	$bootstrap_config['inline_css'] = '.info { font-size: 70%; margin-bottom: 3em; }';
	$bootstrap_config['styles'] = array('css');
	$bootstrap_config['scripts'] = array('jquery_js', 'js');
	
	function echo_err($msg, $exit = true) {
		fwrite(STDERR, "\nERROR: ".$msg."\n");
		if($exit) exit(1);
	}
	
	function generate_table($csvfile, $title = '') {
		
		global $csv_separator, $csv_encoding, $db_encoding, $fields, $filter; 
	
		if(!is_file($csvfile) or !is_readable($csvfile)) {
			echo_err($csvfile.' ist keine gültige Datei!');
		}
			
		$lastupdate = filemtime($csvfile);
		
		$fp = @fopen($csvfile, 'r');
		if($fp === false) {
			echo_err('Kann '.$csvfile.' nicht öffnen!');
		}
		
		$firstline = true;
		$csvheader = array();
		$list = array();

		while (($rawdata = fgetcsv($fp, 1000, $csv_separator)) !== FALSE) {
			
			if($firstline === true) {
				$csvheader = mb_convert_encoding($rawdata, $db_encoding, $csv_encoding);
				$firstline = false;
				continue;
			} 
			
			$data = array();
		
			foreach($csvheader as $k => $v) {
				$data[$v] = $rawdata[$k];
			}
			
			$list[] = $data;
		}
		
		$html = '';
		
		if($title != '') {
			$html .= '<h2>'.$title."</h2>\n";
		}
				
		$html .= '<table class="table table-sm">'."\n<thead>\n<tr>\n";
		
		foreach($fields as $field) {			
			$html .= '<th align="center"><b>'.$field."</b></th>\n";
		}
		
		$html .= "</tr>\n</thead>\n<tbody>\n";
				
		foreach($list as $line) {
			$html .= "<tr>\n";
		
			foreach($fields as $field) {	
				if(array_key_exists($field, $filter)) {
					$f = $filter[$field];
					$s = str_replace($f['s'], $f['r'], $line[$field]);
				} else {
					$s = $line[$field];
				}
				$html .= '<td>'.$s."</td>\n";
			}
			
			$html .= "</tr>\n";					
		}
			
		$html .= "</tbody>\n</table>\n";	
		
		$html .= '<p class="info">Stand: '.date('d.m.Y H:i', $lastupdate)."</p>\n";
			
		return $html;	
	}
	
	### MAIN ###
		
	$template = file_get_contents($templatefile);
	
	if($template === false) {
		echo_err('Kann '.$templatefile.' nicht einlesen!');
	}
	
	$body = '';
	
	foreach($csvs as $t => $csv) {				
		$body .= generate_table($csvpath.'/'.$csv, $t); 
	}
	
	$html = str_replace($yieldtoken, $body, $template);
	
	bootstrap_head('Bestandliste');
	echo $html;
	bootstrap_foot();
	
	exit(0);	

?>