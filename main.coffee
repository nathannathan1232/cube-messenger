login = require('facebook-chat-api')
fs = require('fs')
sleep = require('sleep')

Cube = require('./cube.js')
save_cube_image = require('./image.js')
TimeTracker = require('./time-tracker.js')

LOGIN_USERNAME = process.argv[2]
LOGIN_PASSWORD = process.argv[3]

ALGORITHM_REGEX = /(?:[0-9]?[RLUDFBxyz]['2]? *){3,}/
ALGORITHM_REGEX_NO_MIN = /(?:[0-9]?[RLUDFBxyz]['2]? *)+/

time_tracker = new TimeTracker('times.json')

includes_scramble = (message) ->
	message.match(ALGORITHM_REGEX)

respond = (message) ->
	body = message.body.replace(/’/g, '\'')

	# Generate a scramble
	if body.match(/generate(?: a)? [0-9]+x[0-9]+ scramble/i)
		request = body.match(/[0-9]+x[0-9]+ scramble/i)[0]
		size = parseInt(request.split('x')[0])
		
		if size < 1 or size > 10
			return {
				body: 'Size must be between 1 and 10'
			}

		scramble = Cube.gen_scramble(size)

		cube = new Cube(size).move(scramble)

		save_cube_image(cube, './cube.png')

		return {
			body: scramble
			attachment: fs.createReadStream('./cube.png')
		}

	# Solve a cross
	else if body.match(/solve cross/i)
		scramble = body.match(ALGORITHM_REGEX_NO_MIN)[0].replace(/^ +| +$/g, '')
		
		cube = new Cube(3).move(scramble)

		cross = cube.cross_solutions()

		return {
			body: cross[0]
		}

	# Display scramble
	else if includes_scramble(body)
		scramble = body.match(ALGORITHM_REGEX)[0].replace(/^ +| +$/g, '')

		cube = new Cube(3).move(scramble)

		save_cube_image(cube, './cube.png')

		return {
			body: scramble
			attachment: fs.createReadStream('./cube.png')
		}

	# Set a record
	# Usage: set record Nathan 3x3 ao100 58.33
	else if body.match(/^set records?(?: [a-z0-9_'\-.]+){4}/i)

		request = body.split(' ')
		name   = request[2]
		puzzle = request[3]
		type   = request[4]
		value  = request[5]

		return time_tracker.add_record(puzzle, type, value, name)

	# Get a record
	# Usage: get records for 4x4 ao5
	else if body.match(/^get records?(?: for)?(?: [a-z0-9_'\-.]+){1,2}/i)
		request = body.replace(/for /i, '').split(' ')

		if request.length is 3
			puzzle = request[2]
			
			return time_tracker.get_all_records(puzzle)
			
		else
			puzzle = request[2]
			type   = request[3]

			return time_tracker.get_record(puzzle, type)

	# Delete a record
	# Usage: delete record for 3x3 single Nathan
	else if body.match(/^delete records?(?: for)?(?: [a-z0-9_'\-.]+){2}/i)
		request = body.replace(/for /i, '').split(' ')

		puzzle = request[2]
		type   = request[3]
		name   = request[4]

		return time_tracker.delete_record(puzzle, type, name)

	else if body.match(/^\$help$/)
		return '
			Help:\n
			\t<parameter> [optional parameter]
			\tSet a record: "set record <name> <puzzle> <type> <value>"\n
			\tGet a record: "get records for <puzzle> [type]"\n
			\tDelete a record: "delete record for <puzzle> <type> <name>"\n
			\tList puzzles: "list puzzles"
		'

	else if body.match(/^list puzzles/i)
		res = 'Puzzles:\n'
		
		for i of time_tracker.times
			res += i + '\n'

		return res

login({email: LOGIN_USERNAME, password: LOGIN_PASSWORD}, (err, api) ->
	if err
		throw err

	api.listen((err, message) ->
		throw err if err
		unless message.body
			return

		api.sendMessage(respond(message), message.threadID)
	)
)