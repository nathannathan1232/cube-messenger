COLORS = require('colors')

$ = require('./functions.js')

color_faclet = (n) ->
	c = n + ''
	colors = [
		'white', 'magenta', 'green', 'red', 'blue', 'yellow'
	]
	c[colors[n]] || c

# Parses a move into an object
parse_move = (m) ->
	face = 'R'
	depth = 0
	times = 1

	if m[0].match(/[RUFBDLxyz]/i)
		face = m[0]
		if m[1] and m[1].match(/['2]/)
			times = if m[1] is "'" then 3 else 2
	else
		depth = m[0] - 1
		face = m[1]
		if m[2] and m[2].match(/['2]/)
			times = if m[2] is "'" then 3 else 2

	{ face, depth, times }

# Converts a parsed move object to a string
move_to_string = (m) ->
	depth = if m.depth is 0 then '' else m.depth + 1
	mod = if m.times is 1 then '' else if m.times is 2 then '2' else '\''
	depth + m.face + mod

MOVES = "x R R' R2 L L' L2 U U' U2 D D' D2 F F' F2 B B' B2".split(' ')
FACES = 'RLUDFB'.split('')

# Converts an integer to a set of moves. Used for trying every possible move set.
int_to_moves = (n) ->
	seq = n.toString(MOVES.length)
	res = []
	for i in [0...seq.length]
		unless MOVES[parseInt(seq[i], MOVES.length)] is 'x'
			res.push(MOVES[parseInt(seq[i], MOVES.length)])

	res.join(' ')

random_face = () ->
	return FACES[$.rand_int(0, FACES.length)]

random_mod = () ->
	return if Math.random() < 0.5 then '2' else if Math.random() < 0.5 then '\'' else ''

class Cube

	# Rotates a set of moves to be performed from a different angle
	@rotate_moves = (moves, rotation) ->
		moves = moves.split(' ')
		translations = {
			"x":
				"R": "R", "L": "L",    "U": "B", "D": "F",    "F": "U", "B": "D"
			"x'":
				"R": "R", "L": "L",    "U": "F", "D": "B",    "F": "D", "B": "U"
			"x2":
				"R": "R", "L": "L",    "U": "D", "D": "U",    "F": "B", "B": "F"
			"y":
				"R": "F", "L": "B",    "U": "U", "D": "D",    "F": "L", "B": "R"
			"y'":
				"R": "B", "L": "F",    "U": "U", "D": "D",    "F": "R", "B": "L"
			"y2":
				"R": "L", "L": "R",    "U": "U", "D": "D",    "F": "B", "B": "F"
			"z":
				"R": "D", "L": "U",    "U": "R", "D": "L",    "F": "F", "B": "B"
			"z'":
				"R": "U", "L": "D",    "U": "L", "D": "R",    "F": "F", "B": "B"
			"z2":
				"R": "L", "L": "R",    "U": "D", "D": "U",    "F": "F", "B": "B"
		}
		for i in [0...moves.length]
			m = parse_move(moves[i])
			m.face = translations[rotation][m.face]
			moves[i] = move_to_string(m)

		moves.join(' ')

	@gen_scramble = (size) ->
		moves = []
		maxdepth = Math.floor(size / 2)
		sides = 'FRULDB'
		mods = ' \'2'

		s = 0
		for i in [0...(2.5 * size * size + 2)]
			moves.push((s += Math.floor(Math.random() * 5 + 1)) % 6)


		res = ''

		for i in [0...moves.length]
			depth = Math.floor(Math.random() * maxdepth + 1)
			if depth is 1
				depth = ''
			mod = mods[Math.floor(Math.random() * mods.length)]
			if mod == ' '
				mod = ''
			res += depth + sides[moves[i]] + mod + ' '

		res.replace(/\ +/g, ' ').replace(/\s+$/g, '')

	constructor: (@size) ->
		@state = []
		for i in [0...6]
			for j in [0...(@size * @size)]
				@state.push(i)
		return this

	# Copy the cube
	copy: () ->
		res = new Cube(@size)
		res.state = JSON.parse(JSON.stringify(@state))
		res

	# Gets or sets a faclet given face and x and y coordinates

	at: (side, x, y) ->
		@state[@size * @size * side + @size * y + x]

	set: (side, x, y, c) ->
		@state[@size * @size * side + @size * y + x] = c

	# Displays the cube as colored numbers
	str: () ->
		indent = @size * 2 + 2
		res = ''
		for i in [0...@size]
			res += ' ' for j in [0...indent]
			for j in [0...@size]
				res += color_faclet(@at(0, j, i)) + ' '
			res += '\n'
		res += '\n'

		for y in [0...@size]
			for i in [1...5]
				for x in [0...@size]
					res += color_faclet(@at(i, x, y)) + ' '
				res += '  '
			res += '\n'

		for i in [0...@size]
			res += '\n'
			res += ' ' for j in [0...indent]
			for j in [0...@size]
				res += color_faclet(@at(5, j, i)) + ' '

		res

	face_index: (f) ->
		'ULFRBD'.split('').indexOf(f)

	opposite_face: (f) ->
		{
			'R': 'L',
			'L': 'R',
			'U': 'D',
			'D': 'U',
			'F': 'B',
			'B': 'F',
		}[f]

	turn: (m) ->
		res = @copy()

		m = parse_move(m)

		# Rotate faclets on the face if depth is 0 or size - 1
		if m.depth == 0
			face = @face_index(m.face)
			for x in [0...@size]
				for y in [0...@size]
					res.set(face, x, y, @at(face, y, @size - x - 1))

		if m.depth == @size - 1
			face = @face_index(@opposite_face(m.face))
			for x in [0...@size]
				for y in [0...@size]
					res.set(face, x, y, @at(face, @size - y - 1, x))

		# Turn inner layers
		switch m.face
			when 'R'
				faclets = []
				faclets.push(@at(0, @size - m.depth - 1, @size - i - 1)) for i in [0...@size]
				faclets.push(@at(4, m.depth            ,             i)) for i in [0...@size]
				faclets.push(@at(5, @size - m.depth - 1, @size - i - 1)) for i in [0...@size]
				faclets.push(@at(2, @size - m.depth - 1, @size - i - 1)) for i in [0...@size]

				res.set(4, m.depth            ,             i, faclets[          + i]) for i in [0...@size]
				res.set(5, @size - m.depth - 1, @size - i - 1, faclets[@size * 1 + i]) for i in [0...@size]
				res.set(2, @size - m.depth - 1, @size - i - 1, faclets[@size * 2 + i]) for i in [0...@size]
				res.set(0, @size - m.depth - 1, @size - i - 1, faclets[@size * 3 + i]) for i in [0...@size]

			when 'U'
				faclets = []
				faclets.push(@at(1, @size - i - 1, m.depth)) for i in [0...@size]
				faclets.push(@at(4, @size - i - 1, m.depth)) for i in [0...@size]
				faclets.push(@at(3, @size - i - 1, m.depth)) for i in [0...@size]
				faclets.push(@at(2, @size - i - 1, m.depth)) for i in [0...@size]

				res.set(4, @size - i - 1, m.depth, faclets[          + i]) for i in [0...@size]
				res.set(3, @size - i - 1, m.depth, faclets[@size * 1 + i]) for i in [0...@size]
				res.set(2, @size - i - 1, m.depth, faclets[@size * 2 + i]) for i in [0...@size]
				res.set(1, @size - i - 1, m.depth, faclets[@size * 3 + i]) for i in [0...@size]

			when 'F'
				faclets = []
				faclets.push(@at(0, i                  , @size - m.depth - 1)) for i in [0...@size]
				faclets.push(@at(3, m.depth            , i                  )) for i in [0...@size]
				faclets.push(@at(5, @size - i - 1      , m.depth            )) for i in [0...@size]
				faclets.push(@at(1, @size - m.depth - 1, @size - i - 1      )) for i in [0...@size]

				res.set(3, m.depth            , i                  , faclets[          + i]) for i in [0...@size]
				res.set(5, @size - i - 1      , m.depth            , faclets[@size * 1 + i]) for i in [0...@size]
				res.set(1, @size - m.depth - 1, @size - i - 1      , faclets[@size * 2 + i]) for i in [0...@size]
				res.set(0, i                  , @size - m.depth - 1, faclets[@size * 3 + i]) for i in [0...@size]

			when 'L'
				switch m.times
					when 1
						return @turn((@size - m.depth) + 'R\'')
					when 2
						return @turn((@size - m.depth) + 'R2')
					when 3
						return @turn((@size - m.depth) + 'R')
	
			when 'D'
				switch m.times
					when 1
						return @turn((@size - m.depth) + 'U\'')
					when 2
						return @turn((@size - m.depth) + 'U2')
					when 3
						return @turn((@size - m.depth) + 'U')
				
			when 'B'
				switch m.times
					when 1
						return @turn((@size - m.depth) + 'F\'')
					when 2
						return @turn((@size - m.depth) + 'F2')
					when 3
						return @turn((@size - m.depth) + 'F')
				
			when 'x'
				res = res.turn('R')
				for i in [1...@size]
					res = res.turn((i + 1) + 'R')
				
			when 'y'
				res = res.turn('U')
				for i in [1...@size]
					res = res.turn((i + 1) + 'U')
				
			when 'z'
				res = res.turn('F')
				for i in [1...@size]
					res = res.turn((i + 1) + 'F')
			
		# Rotate again if it's a 2 or ' move
		if --m.times > 0
			return res.turn((m.depth + 1) + m.face + (if m.times > 1 then '2' else ''))

		res

	# Performs a set of moves
	move: (moves) ->
		res = @copy()

		return res if(moves == '')

		moves = moves
			.replace(/\ +/g, ' ')
			.replace(/^ +| +$/g, '')
			.split(' ')

		for i in [0...moves.length]
			res = res.fast_turn(moves[i])

		return res

	# Moves from a prune table, which is faster than a normal move
	move_from_table: (table) ->
		res = new Cube(@size)
		for i in [0...table.length]
			res.state[i] = @state[table[i]]
		
		res

	# On 3x3s, use the prune table to move faster
	fast_turn: (m) ->
		if @size is 3 and TABLES_3.hasOwnProperty(m)
			return @move_from_table(TABLES_3[m])
		else
			return @turn(m)

	# Is the cube solved?
	is_solved: () ->
		for i in [0...@state.length]
			if @state[i] != Math.floor(i / (@size * @size))
				return false
		true

	# Gives the index of a solved cross, otherwise return -1
	cross_done: () ->
		faclets_to_check = [
			[1, 3, 5, 7, 10, 19, 28, 36]
			[10, 12, 14, 16, 21, 3, 41, 48]
			[19, 21, 23, 25, 7, 14, 30, 46]
			[28, 30, 32, 34, 5, 23, 39, 50]
			[37, 39, 41, 43, 1, 32, 52, 12]
			[46, 48, 50, 52, 16, 25, 34, 43]
		]

		for i in [0...faclets_to_check.length]
			solved = true
			for j in [0...faclets_to_check[i].length]
				if @state[faclets_to_check[i][j]] isnt Math.floor(faclets_to_check[i][j] / 9)
					solved = false
					break
			if solved
				return i

		-1

	# Finds solutions for CFOP cross
	cross_solutions: (n = 1) ->
		solutions = []

		i = 0
		while solutions.length < n
			cross = int_to_moves(++i)
			cube = @copy().move(cross)

			if cube.cross_done() >= 0
			
				cross_side = cube.cross_done()
				rotation = ["x2", "z'", "x'", "y", "x", ""][cross_side]
				unless rotation is ''
					cross = rotation + ' ' + Cube.rotate_moves(cross, rotation)
				solutions.push(cross)

			if i % 1000 is 0
				process.stdout.write('\rSolving Cross... ' + solutions.length + '/' + n + ' solutions found at depth ' + (Math.log(i) / Math.log(MOVES.length)).toFixed(2))

		$.clearline()

		solutions

# Prune tables for 3x3
TABLES_3 = {}

gen_tables = () ->
	for i in [1...MOVES.length]
		cube = new Cube(3)
		for j in [0...cube.state.length]
			cube.state[j] = j

		cube = cube.move(MOVES[i])

		TABLES_3[MOVES[i]] = cube.state

gen_tables()

module.exports = Cube