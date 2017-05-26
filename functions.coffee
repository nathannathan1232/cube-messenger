module.exports = {
	last_element: (array) ->
		array[array.length - 1]

	rand_int: (min, max) ->
		Math.floor(Math.random() * (max - min) + min)

	clearline: () ->
		process.stdout.write('\r')
		process.stdout.write(' ') for i in [0...process.stdout.columns]
		process.stdout.write('\r')

	time_to_seconds: (t) ->
		t = String(t)
		unless t.match(/:/)
			return parseFloat(t)

		ms = t.match(/\.[0-9]+$/)[0].replace(/[^0-9]/g, '')
		switch ms.length
			when 1
				ms = parseFloat(ms) / 10
			when 2
				ms = parseFloat(ms) / 100
			when 3
				ms = parseFloat(ms) / 1000
		sec = parseFloat(t.match(/:[0-9]+\./)[0].replace(/[^0-9]/g, ''))
		min = parseFloat(t.match(/^[0-9]+:/)[0].replace(/[^0-9]/g, ''))

		return min * 60 + sec + ms
}