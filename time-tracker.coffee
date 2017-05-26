fs = require('fs')
$ = require('./functions.js')

EVENTS = ['2x2', '3x3', '4x4', '5x5', '6x6', '7x7', 'pyraminx', 'square-one', 'skewb', 'oh', 'feet', 'fmc', '3bld', '4bld', '5bld', 'mbld', 'megaminx', 'clock']
TYPES = ['single', 'mo3', 'ao5', 'ao12', 'ao50', 'ao100', 'ao1000']

class TimeTracker

	constructor: (@filename) ->
		if fs.existsSync(@filename)
			@times = JSON.parse(fs.readFileSync(@filename))
		else
			@times = {}

			for i in [0...EVENTS.length]
				@times[EVENTS[i]] = {
					'single': []
					'mo3': []
					'ao5': []
					'ao12': []
					'ao50': []
					'ao100': []
					'ao1000': []
				}

		@update()

	update: () ->
		for i in [0...EVENTS.length]
			unless @times.hasOwnProperty(EVENTS[i])
				@times[EVENTS[i]] = {}

			for j in [0...TYPES.length]
				unless @times[EVENTS[i]].hasOwnProperty(TYPES[j])
					@times[EVENTS[i]][TYPES[j]] = []
					console.log 'added ' + EVENTS[i] + ' ' + TYPES[j]


	save_times: () ->
		fs.writeFileSync(@filename, JSON.stringify(@times, null, '  '))

	add_record: (puzzle, type, value, name) ->
		unless @times.hasOwnProperty(puzzle)
			return 'Can not find puzzle type ' + puzzle
		unless @times[puzzle].hasOwnProperty(type)
			return 'Can not find records for ' + type

		records = @times[puzzle][type]

		for i in [0...records.length]
			if records[i].name is name
				if records[i].value < value
					return name + '\'s best time for ' + puzzle + ' ' + type + ' is ' + records[i].value
				else
					records[i].value = value
					@save_times()
					return 'set ' + name + '\'s time for ' + puzzle + ' ' + type + ' to ' + records[i].value

		records.push({
			name, value
		})
		@save_times()

		return 'set ' + name + '\'s time for ' + puzzle + ' ' + type + ' to ' + $.last_element(records).value

	get_record: (puzzle, type) ->
		unless @times.hasOwnProperty(puzzle)
			return 'Can not find puzzle type ' + puzzle
		unless @times[puzzle].hasOwnProperty(type)
			return 'Can not find records for ' + type

		res = 'Fastest times for ' + puzzle + ' ' + type + ' ->\n'

		records = @times[puzzle][type].sort((a, b) ->
			$.time_to_seconds(a.value) - $.time_to_seconds(b.value)
		)

		if records.length < 1
			return 'No records for ' + puzzle + ' ' + type

		for i in [0...records.length]
			res += '(' + (i + 1) + ') ' + records[i].name + ': ' + records[i].value + '\n'

		return res

	get_all_records: (puzzle) ->
		if @times.hasOwnProperty(puzzle)
			res = puzzle + ' ->\n'

			for i in [0...TYPES.length]
				res += '\t' + TYPES[i] + ':\n'
				records = @times[puzzle][TYPES[i]].sort((a, b) ->
					$.time_to_seconds(a.value) - $.time_to_seconds(b.value)
				)

				for j in [0...records.length]
					res += '\t\t(' + (j + 1) + ') ' + records[j].name + ': ' + records[j].value + '\n'

			return res
		else
			res = puzzle + ' ->\n'

			for i in [0...EVENTS.length]
				for j in [0...TYPES.length]
					records = @times[EVENTS[i]][TYPES[j]]
					for k in [0...records.length]
						if records[k].name is puzzle
							res += '\t' + EVENTS[i] + ' ' + TYPES[j] + ': ' + records[k].value + '\n'

			return res

	delete_record: (puzzle, type, name) ->
		unless @times.hasOwnProperty(puzzle)
			return 'Can not find puzzle type ' + puzzle
		unless @times[puzzle].hasOwnProperty(type)
			return 'Can not find records for ' + type

		records = @times[puzzle][type]

		for i in [0...records.length]
			if records[i].name is name
				records.splice(i, 1)
				@save_times()
				return 'Deleted ' + name + '\'s time for ' + puzzle + ' ' + type

		return 'Can not find ' + name + '\'s time for ' + puzzle + ' ' + type

module.exports = TimeTracker