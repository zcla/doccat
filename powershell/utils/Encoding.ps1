function Convert-UnicodeC1ControlCharacters_to_HtmlEntities($str) {
	# https://en.wiktionary.org/wiki/Appendix:Control_characters#C1_set
	# http://www.i18nqa.com/debug/table-iso8859-1-vs-windows-1252.html#compare
	$REPLACEMENTS = @{
		[char]128 = '&euro;'
		[char]129 = '&#129;'
		[char]130 = '&sbquo;'
		[char]131 = '&#x192;'
		[char]132 = '&bdquo;'
		[char]133 = '&hellip;'
		[char]134 = '&dagger;'
		[char]135 = '&Dagger;'
		[char]136 = '&circ;'
		[char]137 = '&permil;'
		[char]138 = '&Scaron;'
		[char]139 = '&lsaquo;'
		[char]140 = '&OElig;'
		[char]141 = '&#141;'
		[char]142 = '&#x17D;'
		[char]143 = '&#143;'
		[char]144 = '&#144;'
		[char]145 = '&lsquo;'
		[char]146 = '&rsquo;'
		[char]147 = '&ldquo;'
		[char]148 = '&rdquo;'
		[char]149 = '&bull;'
		[char]150 = '&ndash;'
		[char]151 = '&mdash;'
		[char]152 = '&tilde;'
		[char]153 = '&trade;'
		[char]154 = '&scaron;'
		[char]155 = '&rsaquo;'
		[char]156 = '&oelig;'
		[char]157 = '&#157;'
		[char]158 = '&#x17E;'
		[char]159 = '&Yuml;'
	}
	
	$result = $str
	foreach ($char in $REPLACEMENTS.Keys) {
		$result = $result -replace $char, $REPLACEMENTS.$char
	}

	return $result
}
