mysql = require('mysql')
login = require('facebook-chat-api')

LOGIN_USERNAME = process.argv[2]
LOGIN_PASSWORD = process.argv[3]

EVENTS = ['2x2', '3x3', '4x4', '5x5', '6x6', '7x7', 'oh', 'square-1', 'pyraminx', 'skewb', 'megaminx', 'clock', '3bld', '4bld', '5bld', 'mini-guildford', '2x2-5x5', '2x2-7x7']
TYPES = ['single', 'ao3', 'ao5', 'ao12', 'ao50', 'ao100', 'ao1000']

conn = mysql.createConnection({
	host: 'localhost',
	user: 'root',
	password: 'sql87',
	database: 'cubes'
})

conn.connect()

parse_time = (t) ->
	if t.match(/^[0-9]+\.[0-9]+$/)
		min = '0'
		sec = t.split('.')[0]
		ms = t.split('.')[1]
	else if t.match(/^[0-9]+\:[0-9]+\.[0-9]+$/)
		min = t.split(':')[0]
		t = t.replace(/^[0-9]+\:/, '')
		sec = t.split('.')[0]
		ms = t.split('.')[1]
	else if t.match(/^[0-9]+\:[0-9]+$/)
		min = t.split(':')[0]
		sec = t.split(':')[1]
		ms = '0'
	else if t.match(/^[0-9]+$/)
		min = '0'
		sec = t
		ms = '0'
	else if t.match(/^\.[0-9]+$/)
		min = '0'
		sec = '0'
		ms = t.replace(/\./, '')
	else
		return false

	while ms.length < 3
		ms += '0'

	return [parseInt(min), parseInt(sec), parseInt(ms)]

time_to_str = (min, sec, ms) ->
	smin = if min > 0 then min + ':' else ''

	sec = sec.toString()
	while sec.length < 2
		sec = '0' + sec

	ms = ms.toString()
	while ms.length < 3
		ms += '0'

	while ms[ms.length - 1] is '0' and ms.length > 2
		ms = ms.substr(0, ms.length - 1)

	return smin + sec + '.' + ms

respond = (msg, api, thread) ->
	console.log msg
	if msg.match(/^set records?(?: .+){4}/i)
		m = msg.split(' ')
		name = m[2]
		puzzle = m[3]
		type = m[4]
		value = m[5]

		if type is 'mo3'
			type = 'ao3'

		time = parse_time(value)

		unless EVENTS.includes(puzzle)
			api.sendMessage('No event named ' + puzzle, thread)
			return

		unless TYPES.includes(type)
			api.sendMessage('No categiry named ' + type, thread)
			return

		unless time
			api.sendMessage('Invalid time format.', thread)

		conn.query('DELETE FROM records WHERE user = ? and puzzle = ? and type = ?', [name, puzzle, type])

		conn.query('INSERT INTO records (user, puzzle, type, minutes, seconds, ms) VALUES(?, ?, ?, ?, ?, ?)', [name, puzzle, type, time[0], time[1], time[2]])

		return api.sendMessage('Record set for ' + name + ' ' + puzzle + ' ' + type + ' to ' + value, thread)

	else if msg.match(/^get records?(?: .+)+/i)
		m = msg.split(' ')

		if EVENTS.includes(m[2])

			conn.query('SELECT * FROM records WHERE puzzle = ? ORDER BY minutes, seconds, ms', [m[2]], (err, result, fld) ->
				throw err if err

				res = m[2] + ' ->\n'
				for i in [0...TYPES.length]
					res += TYPES[i] + '\n'
					for j in [0...result.length]
						if result[j].type is TYPES[i]
							res += '  ' + result[j].user + ': ' + time_to_str(result[j].minutes, result[j].seconds, result[j].ms) + '\n'

				console.log res

				api.sendMessage(res, thread)
			)

		else

			conn.query('SELECT * FROM records WHERE user = ? ORDER BY minutes, seconds, ms', [m[2]], (err, result, fld) ->
				throw err if err

				res = m[2] + ' ->\n'
				for i in [0...EVENTS.length]
					for j in [0...TYPES.length]
						for k in [0...result.length]
							if result[k].puzzle is EVENTS[i] and result[k].type is TYPES[j]
								res += '  ' + EVENTS[i] + ' ' + TYPES[j] + ': ' + time_to_str(result[k].minutes, result[k].seconds, result[k].ms) + '\n'

				console.log res

				api.sendMessage(res, thread)
			)

	else if msg.match(/^delete records?(?: .+){3}/i)
		m = msg.split(' ')

		conn.query('DELETE FROM records WHERE user = ? and puzzle = ? and type = ?', [m[2], m[3], m[4]])

		api.sendMessage('Deleted ' + m[2] + '\'s time for ' + m[3] + ' ' + m[4], thread)

	else if msg.match(/^\$help/i)

		api.sendMessage('
			Use the graphical interface at: http://67.182.154.189\n

			Commands:\n
			Set record: "set record <name> <puzzle> <category> <time>"\n
			Get records: "get records <puzzle/name>"\n
			Delete record: "delete record <name> <puzzle> <category>"
		', thread)

	else if msg.match(/^list puzzles/)

		res = ''
		for i in [0...EVENTS.length]
			res += EVENTS[i] + '\n'

		api.sendMessage(res, thread)

login({email: LOGIN_USERNAME, password: LOGIN_PASSWORD}, (err, api) ->
	throw err if err

	api.listen((err, message) ->
		throw err if err
		unless message.body
			return

		messages = message.body.split('&& ')
		for i in [0...messages.length]
			respond(messages[i], api, message.threadID)
	)
)
