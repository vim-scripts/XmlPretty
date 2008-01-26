function! XmlPretty()
	let bufnum = bufnr("%")
	let linearray = getbufline(bufnum, 1, "$")

	" Get the whole buffer into one string
	let buf = ''
	let index = 0
	while index <= len(linearray)
		let o = getline(index)
		let buf = buf . o
		let index = index + 1
	endwhile
	
	" Generate indexes of all of the xml tags in the buffer
	let regex = "<\\(\\/\\)\\?[a-zA-Z0-9-._:]*\\(\\( [a-zA-Z_:][a-zA-Z0-9.-_:]*=\\([\"][^\"]\\+[\"]\\)\\|\\(['][^']\\+[']\\)\\)*\\)\\? *\\(\\/\\)\\?>"

	let match = {'start': 0, 'end': 0, 'len': 0, 'endnode': 0, 'selfterm': 0}
	let matches = [match]
	while match['start'] > -1
		call add(matches, match)

		let start = match(buf, regex, matches[-1]['end'])
		if start > -1
			let rawmatch = matchlist(buf, regex, matches[-1]['end'])

			let end = start + len(rawmatch[0])
			let endnode = len(rawmatch[1])
			let selfterm = len(rawmatch[6])
		endif

		let match = {'start': start, 'end': end, 'len': end - start, 'endnode': endnode, 'selfterm': selfterm}
	endwhile

	" remove first entry - it was a dummy
	call remove(matches, 0, 1)

	" generates whitespace
	function! Whitespace(indent)
		let tabstop = 3

		return repeat(' ', a:indent * tabstop)
	endfunction

	" Rewrite the buffer line by line with indentation
	let line = 1
	let indent = 0
	for x in range(len(matches))
		let match = matches[x]
		let part = strpart(buf, match['start'], match['len'])

		if x != 0
			if (matches[x]['start'] - matches[x-1]['end']) > 1
				let text = strpart(buf, matches[x-1]['end'], matches[x]['start'] - matches[x-1]['end'])
				
				" trim
				let text = substitute(text, "^[ \t]*", '', '')
				let text = substitute(text, "[ \t]*$", '', '')

				if len(text)
					call setline(line, Whitespace(indent) . text)
					let line = line + 1
				endif
			endif
		endif

		if match['selfterm']
			call setline(line, Whitespace(indent) . part)
		elseif match['endnode']
			let indent = indent - 1
			call setline(line, Whitespace(indent) . part)
		else
			call setline(line, Whitespace(indent) . part)
			let indent = indent + 1
		endif

		let line = line + 1
	endfor
	if(len(linearray) >= line)
		for x in range(len(linearray) - line + 1)
			call setline(x+line, '')
		endfor
		call cursor(len(linearray), 1)
		for x in range(len(linearray) - line + 1)
			exe 'normal ' . "a\b\e"	
		endfor
	endif
endfunction
