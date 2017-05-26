PNG = require('pngjs').PNG
fs = require('fs')

# Syncronously writes a PNG to file
save_image = (name, png) ->
	options = {colorType: 6}
	png.buffer = png.data
	buffer = PNG.sync.write(png, options)
	fs.writeFileSync(name, buffer)

# Get the color of a faclet
faclet_to_hex = (n) ->
	return [
		[0xF0, 0xF0, 0xF0, 0xFF]
		[0xFF, 0x7A, 0x0C, 0xFF]
		[0x0D, 0xE2, 0x2A, 0xFF]
		[0xFF, 0x0C, 0x0C, 0xFF]
		[0x0C, 0x69, 0xE2, 0xFF]
		[0xFF, 0xFF, 0x00, 0xFF]
	][n]

# Set a pixel of a PNG
png_set = (png, y, x, color) ->
	idx = (png.width * y + x) << 2

	png.data[idx] = color[0]
	png.data[idx + 1] = color[1]
	png.data[idx + 2] = color[2]
	png.data[idx + 3] = color[3]

# Generates and saves the image of a cube
save_cube_image = (cube, name) ->
	faclet_size = Math.floor(30 / cube.size) + 8
	height = (cube.size * (faclet_size + 1) * 3) + 5
	width = (cube.size * (faclet_size + 1) * 4) + 7

	# Color the background black
	data = []
	for i in [0...(width * width * 4)]
		data[i] = if i % 4 is 3 then 255 else 0

	image = new PNG({
		width, height
	})

	image.data = data

	indent = cube.size * (faclet_size + 1) + 3

	# Top
	for i in [0...cube.size]
		for j in [0...cube.size]
			for x in [0...faclet_size]
				for y in [0...faclet_size]
					png_set(
						image,
						i * (faclet_size + 1) + 1 + y,
						indent + j * (faclet_size + 1) + x,
						faclet_to_hex(cube.at(0, j, i))
					)

	# Front and Sides
	for y in [0...cube.size]
		for i in [1...5]
			for x in [0...cube.size]
				for xp in [0...faclet_size]
					for yp in [0...faclet_size]
						png_set(
							image,
							y * (faclet_size + 1) + cube.size * (faclet_size + 1) + 3 + yp,
							x * (faclet_size + 1) + (i - 1) * cube.size * (faclet_size + 1) + (i - 1) * 2 + 1 + xp,
							faclet_to_hex(cube.at(i, x, y))
						)
	
	# Bottom
	for i in [0...cube.size]
		for j in [0...cube.size]
			for x in [0...faclet_size]
				for y in [0...faclet_size]
					png_set(
						image,
						i * (faclet_size + 1) + y + cube.size * (faclet_size + 1) * 2 + 5,
						indent + j * (faclet_size + 1) + x,
						faclet_to_hex(cube.at(5, j, i))
					)
	
	save_image(name, image)

module.exports = save_cube_image