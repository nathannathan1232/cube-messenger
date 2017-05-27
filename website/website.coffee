http = require('http')
fs = require('fs')

$ = require('./functions.js')

hostname = '127.0.0.1'
port = '8005'

space_before = (str, n) ->
	while str.length < n
		str = ' ' + str
	return str

space_after = (str, n) ->
	while str.length < n
		str += ' '
	return str

generate_top_scores = () ->
	res = ""
	scores = JSON.parse(fs.readFileSync('./times.json'))

	for i of scores
		res += "<div class='scoreboard'>" + "<div class='puzzlename'>" + i + "</div>"
		for j of scores[i]
			records = scores[i][j].sort((a, b) ->
				$.time_to_seconds(a.value) - $.time_to_seconds(b.value)
			)

			if records.length > 0
				res += "<div class='time'>" + space_before(j, 8) + " " + space_before(records[0].name, 10) + ":      " + space_after(records[0].value, 12) + "</div>"
			else
				res += "<div class='time'>" + space_before(j, 8) + space_before('-', 11) + space_before('-', 10) + "</div>"
			

		res += "</div>"

	return res

generate_puzzle_scores = () ->
	res = ""
	scores = JSON.parse(fs.readFileSync('./times.json'))

	for i of scores
		res += "<h2>" + i + "</h2><p>"
		for j of scores[i]
			res += "<h3>" + j + "</h3>"
			records = scores[i][j].sort((a, b) ->
				$.time_to_seconds(a.value) - $.time_to_seconds(b.value)
			)

			for k in [0...records.length]
				res += "<div class='time'>(" + (k + 1) + ") " + space_before(records[k].name, 10) + ": " + space_before(records[k].value, 12) + "</div>"

		res += "</p>"

	return res


generate_user_scores = (user) ->
	if user

		res = ""

		scores = JSON.parse(fs.readFileSync('./times.json'))

		res += "<h2>" + user + "</h2>"

		for j of scores
			res += "<h3>" + j + "</h3>"
			for k of scores[j]
				for l in [0...scores[j][k].length]
					if scores[j][k][l].name is user
						res += "<div class='time'>" + space_before(k, 8) + " " + scores[j][k][l].value + "</div>"

		return res

	else
		return "
			<p style='text-align: center; width: 100%;'>Please enter a user's name to view times.</p>

			<input style='margin: auto; display: block; width: 500px; height: 40px;' id='name'></input>
			<button style='margin: auto; width: 500px; height: 40px; display: block;' onclick=\"window.location = './users.html?' + document.getElementById('name').value\">View Times</button>
		"

add_content = (html, args) ->

	return html
		.replace(/\$TOP_SCORES/, generate_top_scores())
		.replace(/\$PUZZLES/, generate_puzzle_scores())
		.replace(/\$USERS/, generate_user_scores(args[1]))
		.replace(/\$STYLESHEET/, '<style>' + fs.readFileSync('./main.css').toString() + '</style>')
		.replace(/\$NAVBAR/, fs.readFileSync('./navbar.html').toString())

server = http.createServer((req, res) ->
	if req.url.match(/favicon/)
		return

	res.statusCode = 200

	res.setHeader('Content-Type', 'text/html')

	args = req.url.split('?')

	file = '.' + args[0]

	console.log args

	if file.length > 3 and fs.existsSync(file)
		res.end(add_content(fs.readFileSync(file).toString(), args))
	else
		res.end(add_content(fs.readFileSync('index.html').toString(), args))
)

server.listen(port, "0.0.0.0", () ->
	console.log('Server running at ' + hostname + ':' + port)
)