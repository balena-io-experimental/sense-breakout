_ = require 'lodash'
Promise = require 'bluebird'

try
	senseJoystick = require 'sense-joystick'
	senseLeds = require 'sense-hat-led'
catch
	color = require('colors/safe')
	DISPLAY_CHAR = ' -'
	BG_COLOUR = color.bgCyan

	releaseCb = null
	senseJoystick =
		getJoystick: Promise.method ->
			on: (evt, cb) ->
				switch evt
					when 'press'
						setInterval((->cb('click')), 500)
						setInterval((->cb('right'); releaseCb()), 2000)
						Promise.resolve('click')
						.then(cb)
						# TEST CORNER PADDLE BOUNCE WITH LEVEL 0
						# .return('left')
						# .tap(cb)
						# .then(cb)
						# .then(releaseCb)

						# .delay(2000)
						# .return('right')
						# .then(cb)
						# .delay(1000)
						# .return('right')
						# .then(cb)
						# .delay(1000)
						# .return('right')
						# .then(cb)
						# .delay(1000)
						# .return('left')
						# .then(cb)
					when 'release'
						releaseCb = cb
						# releaseInterval = setInterval(cb, 1000)
						# setTimeout((-> clearInterval(releaseInterval)), 10000)

	bgColorify = (rgb, text) ->
		if _.isEqual(rgb, BLACK)
			BG_COLOUR(text)
		else if _.isEqual(rgb, RED)
			color.bgRed(text)
		else if _.isEqual(rgb, GREEN)
			color.bgGreen(text)
		else if _.isEqual(rgb, BLUE)
			color.bgBlue(text)
		else
			console.trace("Unknown colour: #{rgb}")
			color.bgMagenta(text)

	senseLeds =
		showMessage: (message, rgb, done) ->
			console.log(bgColorify(rgb, message))
			console.log(bgColorify(rgb, message))
			console.log(bgColorify(rgb, message))
			console.log(bgColorify(rgb, message))
			console.log(bgColorify(rgb, message))
			done()

		setPixels: (arr) ->
			str = '\n'
			for y in [0...HEIGHT]
				for x in [0...WIDTH]
					pixel = arr[position({ x, y })]
					str += bgColorify(pixel, DISPLAY_CHAR)
				str += '\n'
			console.log(str)

senseLeds = Promise.promisifyAll(senseLeds)

updatesDisabled = false

TICK_SPEED = process.env.TICK_SPEED || 400
MOVE_HOLD_SPEED = process.env.MOVE_HOLD_SPEED || 200

colour = (r, g, b) ->
	[r, g, b]

BLACK = colour(0,0,0)
RED = colour(255,0,0)
GREEN = colour(0,255,0)
BLUE = colour(0,0,255)


HEIGHT = 8
WIDTH = 8

PLAYER_START = { x: 3, y: 7 }
BALL_START = { x: 4, y: 6 }
# TEST Y FLAT BOUNCE WITH LEVEL 0
# BALL_START = { x: 2, y: 6 }


clampX = (x) ->
	return (x + WIDTH) % WIDTH
clampY = (y) ->
	return (y + HEIGHT) % HEIGHT
position = ({ x, y }) ->
	if x < 0 or x >= WIDTH
		throw new Error("x is out of bounds: #{x}")
	if y < 0 or y >= HEIGHT
		throw new Error("y is out of bounds: #{y}")
	return x + WIDTH * y

positionToPoint = (pos) ->
	x = pos % WIDTH
	y = pos // WIDTH
	return {x, y}

transformPoint = ({ x, y }, deltaX = 0, deltaY = 0, wrap = true) ->
	x += deltaX
	y += deltaY
	if wrap
		x = clampX(x)
		y = clampY(y)
	return { x, y }

allPoints = (actor, fn) ->
	for x in [0...actor.width]
		for y in [0...actor.height]
			point = transformPoint(actor.point, x, y)
			fn(point)

outOfBounds = (val, limit) ->
	return val < 0 or val >= limit

outOfBoundsPoint = (point) ->
	return outOfBounds(point.x, WIDTH) or outOfBounds(point.y, WIDTH)

displayPoint = (point) ->
	"x: #{point.x}, y: #{point.y}"

class Actor
	constructor: (@board, @colour, @point, @width, @height) ->
		@board.add(this)
	move: (x, y) ->
		@board.move(this, x, y)
	set: (point) ->
		@board.set(this, point)

class Player extends Actor
	constructor: (board) ->
		super(board, BLUE, PLAYER_START, 3, 1)

class Block extends Actor
	constructor: (board, point) ->
		super(board, RED, point, 1, 1)

	onDestroy: (@onDestroyCb) ->
	destroy: ->
		@board.delete(this)
		@onDestroyCb()
		@onDestroyCb = null

destroyBlock = (block) ->
	if block instanceof Block
		block.destroy()

class Ball extends Actor
	constructor: (board) ->
		super(board, GREEN, BALL_START, 1, 1)
		@reset()

	reset: ->
		@stop()
		@set(BALL_START)
		@deltaX = 1
		@deltaY = -1

	checkCollisionBounce:  ->
		collisionPoint = transformPoint(@point, @deltaX, @deltaY, false)
		# console.log("collision point #{displayPoint(collisionPoint)}")
		if outOfBoundsPoint(collisionPoint) or (collision = @board.get(collisionPoint))?
			xDir = Math.sign(@deltaX)
			xPoint = transformPoint(collisionPoint, -xDir, null, false)
			xCollision = outOfBoundsPoint(xPoint) or (xBlock = @board.get(xPoint))?

			yDir = Math.sign(@deltaY)
			yPoint = transformPoint(collisionPoint, 0, -yDir, false)
			yCollision = outOfBoundsPoint(yPoint) or (yBlock = @board.get(yPoint))?

			# console.log("x point #{displayPoint(xPoint)}")
			# console.log("y point #{displayPoint(yPoint)}")

			if xCollision and yCollision
				destroyBlock(collision)
				destroyBlock(xBlock)
				destroyBlock(yBlock)
				@deltaX = -@deltaX
				@deltaY = -@deltaY
			else if xCollision
				destroyBlock(xBlock)
				@deltaY = -@deltaY
			else if yCollision
				destroyBlock(yBlock)
				@deltaX = -@deltaX
			else
				destroyBlock(collision)
				@deltaX = -@deltaX
				@deltaY = -@deltaY
			return true
		return false

	move: =>
		# if outOfBounds(@point.x + @deltaX, WIDTH)
		# 	@deltaX = -@deltaX
		# if outOfBounds(@point.y + @deltaY, WIDTH)
		# 	@deltaY = -@deltaY

		# console.log("before #{@deltaX} #{@deltaY}")
		while(@checkCollisionBounce())
			true
		if @point.y + @deltaY <= 0
			breakout.lose()
			return
		# console.log("after #{@deltaX} #{@deltaY}")


		super(@deltaX, @deltaY)

	start: ->
		return if @moveInterval?
		@moveInterval = setInterval(@move, TICK_SPEED)

	stop: ->
		clearInterval(@moveInterval)
		@moveInterval = null


class Board
	constructor: ->
		@board = _.times(HEIGHT * WIDTH, _.constant(null))
		@update()

	get: (point) ->
		pos = position(point)
		return @board[pos]

	add: (actor) ->
		if not (actor instanceof Actor)
			throw new Error("Adding a non actor #{actor}")
		allPoints actor, (point) =>
			pos = position(point)
			if @board[pos] isnt null
				throw new Error("Somethings already there! #{displayPoint(point)}")
				return false
			@board[pos] = actor
			pos = position(point)
			@board[pos] = actor
		@update()
		return true

	delete: (actor) ->
		allPoints actor, (point) =>
			pos = position(point)
			if @board[pos] is null
				throw new Error("Nothing's even there! #{displayPoint(point)}")
			@board[pos] = null

	move: (actor, deltaX, deltaY) ->
		@set(actor, transformPoint(actor.point, deltaX, deltaY))

	set: (actor, point) ->
		@delete(actor)
		actor.point = point
		@add(actor)
		@update()

	update: ->
		return if updatesDisabled
		pixels = _.map @board, (actor) ->
			if !actor?
				return BLACK
			return actor.colour
		senseLeds.setPixels(pixels)

levels =
	[
		# 0: TEST CORNER BOUNCE
		[
			[ 1, 1, 1, 1, 1, 1, 1, 1]
			[ 1, 1, 1, 1, 1, 1, 1, 1]
			[ 1, 1, 1, 1, 1, 1, 1, 1]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
		]
		# 1: TEST X FLAT BOUNCE
		[
			[ 1, 1, 1, 1, 1, 1, 0, 0]
			[ 1, 1, 1, 1, 1, 1, 0, 0]
			[ 1, 1, 1, 1, 1, 1, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
		]
		# 2: TEST EZ WIN
		[
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 1]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
			[ 0, 0, 0, 0, 0, 0, 0, 0]
		]
	]

class Breakout
	constructor: ->
		@level = 2
		@blocks = []
		@board = new Board()
		@player = new Player(@board)
		@ball = new Ball(@board)
		@generateLevel()

	generateLevel: ->
		shouldHaveBlock = (x, y) =>
			if levels[@level]?
				levels[@level][y][x] is 1
			else if not @board.get({ x, y })?
				y < 5 and _.random(0, @level) > 0

		updatesDisabled = true
		for y in [0...HEIGHT]
			for x in [0...WIDTH] when shouldHaveBlock(x, y)
				do =>
					block = new Block(@board, { x, y })
					@blocks.push(block)
					block.onDestroy =>
						_.pull(@blocks, block)
						if @blocks.length is 0
							# WIN!
							@win()
		updatesDisabled = false
		@board.update()

	right: ->
		@player.move(1, 0)

	left: ->
		@player.move(-1, 0)

	start: ->
		@ball.start()

	reset: ->
		updatesDisabled = true
		for block in @blocks
			@board.delete(block)
		@blocks = []
		@ball.reset()
		@board.set(@player, PLAYER_START)
		updatesDisabled = false
		@board.update()

	win: ->
		@reset()
		@level++
		updatesDisabled = true
		senseLeds.showMessageAsync('Win!', GREEN)
		.delay(1000)
		.then =>
			@generateLevel()


	lose: ->
		@reset()
		@level = 0
		updatesDisabled = true
		senseLeds.showMessageAsync('Loser..', RED)
		.delay(1000)
		.then =>
			@generateLevel()



senseJoystick.getJoystick()
.then (joystick) ->
	right = _.bind(breakout.right, breakout)
	left = _.bind(breakout.left, breakout)
	evtInterval = null
	move = (fn) ->
		clearInterval(evtInterval)
		fn()
		evtInterval = setInterval(fn, MOVE_HOLD_SPEED)


	joystick.on 'release', ->
		clearInterval(evtInterval)

	joystick.on 'press', (val) ->
		return if updatesDisabled
		switch val
			when 'click'
				breakout.start()
			# when 'up'
			when 'right'
				move(right)
			# when 'down'
			when 'left'
				move(left)

# Move object creation after we start the super slow joystick code to speed up bootup a bit
breakout = new Breakout()
