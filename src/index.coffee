_ = require 'lodash'
Promise = require 'bluebird'

if process.env.RESIN is '1'
	senseJoystick = require 'sense-joystick'
	senseLeds = require 'sense-hat-led'
else
	senseJoystick =
		getJoystick: Promise.method ->
			on: (evt, cb) ->
				switch evt
					when 'press'
						Promise.delay(2000)
						.return('right')
						.then(cb)
						.delay(1000)
						.return('right')
						.then(cb)
						.delay(1000)
						.return('right')
						.then(cb)
						.delay(1000)
						.return('left')
						.then(cb)
					when 'release'
						releaseInterval = setInterval(cb, 1000)
						setTimeout((-> clearInterval(releaseInterval)), 10000)

	senseLeds =
		setPixels: (arr) ->
			console.log()
			for y in [HEIGHT-1..0]
				str = ''
				for x in [0...WIDTH]
					pixel = arr[position({ x, y })]
					if _.isEqual(pixel, BLACK)
						str += '.'
					else if _.isEqual(pixel, RED)
						str += 'R'
					else if _.isEqual(pixel, GREEN)
						str += 'G'
					else if _.isEqual(pixel, BLUE)
						str += 'B'
					else
						console.log('F: ', pixel, position({ x, y }), x, y)
						str += 'F'
				console.log(str)
			console.log()

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

clampX = (x) ->
	return (x + WIDTH) % WIDTH
clampY = (y) ->
	return (y + HEIGHT) % HEIGHT
position = ({ x, y }) ->
	if x < 0 or x >= WIDTH
		throw new Error("x is out of bounds: ${x}")
	if y < 0 or y >= HEIGHT
		throw new Error("y is out of bounds: ${y}")
	return x + WIDTH * y

positionToPoint = (pos) ->
	console.log('pos', pos)
	x = pos % WIDTH
	y = pos // WIDTH
	return {x, y}

transformPoint = ({ x, y }, deltaX = 0, deltaY = 0) ->
	x = clampX(x + deltaX)
	y = clampY(y + deltaY)
	return { x, y }

allPoints = (actor, fn) ->
	for x in [0...actor.width]
		for y in [0...actor.height]
			point = transformPoint(actor.point, x, y)
			fn(point)

class Actor
	constructor: (@board, @colour, @point, @width, @height) ->
		@board.add(this)
	move: (x, y) ->
		@board.move(this, x, y)

class Player extends Actor
	constructor: (board) ->
		super(board, BLUE, { x: 3, y: 0 }, 3, 1)

class Block extends Actor
	constructor: (board, point) ->
		super(board, RED, point, 1, 1)

class Ball extends Actor
	constructor: (board) ->
		super(board, GREEN, { x: 4, y: 1 }, 1, 1)

class Board
	constructor: ->
		@board = _.times(HEIGHT * WIDTH, _.constant(null))
		@update()

	add: (actor) ->
		if not (actor instanceof Actor)
			throw new Error("Adding a non actor #{actor}")
		allPoints actor, (point) =>
			pos = position(point)
			if @board[pos] isnt null
				throw new Error("Somethings already there! #{point}")
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
				throw new Error("Nothing's even there! #{point}")
			@board[pos] = null

	move: (actor, deltaX, deltaY) ->
		@delete(actor)
		actor.point = transformPoint(actor.point, deltaX, deltaY)
		@add(actor)
		@update()

	update: ->
		pixels = _.map @board, (actor) ->
			if !actor?
				return BLACK
			return actor.colour
		senseLeds.setPixels(pixels)


class Breakout
	constructor: ->
		@level = 1
		@blocks = []
		@board = new Board()
		@player = new Player(@board)
		@ball = new Ball(@board)
		@generateLevel()

	generateLevel: ->
		for y in [HEIGHT-4...HEIGHT]
			for x in [0...WIDTH] when _.random(0, @level) > 0
				block = new Block(@board, { x, y })
				@blocks.push(block)

	right: ->
		@player.move(1, 0)

	left: ->
		@player.move(-1, 0)


senseJoystick.getJoystick()
.then (joystick) ->
	breakout = new Breakout()
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
		switch val
			# when 'click'
			# when 'up'
			when 'right'
				move(right)
			# when 'down'
			when 'left'
				move(left)