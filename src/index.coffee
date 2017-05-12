if process.env.RESIN is '1'
	senseJoystick = require 'sense-joystick'
	senseLeds = require 'sense-hat-led'
else
	senseLeds =
		setPixels: (arr) ->
			console.log()
			for x in [0...HEIGHT]
				str = ''
				for y in [0...WIDTH]
					pixel = arr[position(x,y)]
					if _.isEqual(pixel, BLACK)
						str += '.'
					else if _.isEqual(pixel, RED)
						str += 'R'
					else if _.isEqual(pixel, GREEN)
						str += 'G'
					else if _.isEqual(pixel, BLUE)
						str += 'B'
					else
						console.log('F: ', pixel, position(x,y), x, y)
						str += 'F'
				console.log(str)
			console.log()
_ = require 'lodash'
Promise = require 'bluebird'

TICK_SPEED = process.env.TICK_SPEED || 400;

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
position = (x, y) ->
	if x < 0 or x >= WIDTH
		throw new Error("x is out of bounds: ${x}")
	if y < 0 or y >= HEIGHT
		throw new Error("y is out of bounds: ${y}")
	return x + WIDTH * y

positionXY = (pos) ->
	x = pos % WIDTH
	y = pos // WIDTH
	return {x, y}

class Actor
	constructor: (@board, @colour, @position) ->
		@board.add(this)
	move: (x, y) ->
		@board.move(this, x, y)

class Player extends Actor
	constructor: (board) ->
		super(board, BLUE, position(0, 4))

class Block extends Actor
	constructor: (board, x, y) ->
		super(board, RED, position(x, y))

class Ball extends Actor
	constructor: (board) ->
		super(board, GREEN, position(1, 4))

class Board
	constructor: ->
		@board = _.times(HEIGHT * WIDTH, _.constant(null))
		@update()

	add: (actor) ->
		if not (actor instanceof Actor)
			throw new Error("Adding a non actor #{actor}")
		pos = actor.position
		if @board[pos] isnt null
			return false
		@board[pos] = actor
		@update()
		return true

	delete: (actor) ->
		@board[actor.position] = null

	move: (actor, deltaX, deltaY) ->
		@delete(actor)
		{ x, y } = positionXY(actor.position)
		x = clampX(x + deltaX)
		y = clampY(y + deltaY)
		pos = position(x, y)
		actor.position = pos

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
		for x in [HEIGHT-4...HEIGHT]
			for y in [0...WIDTH] when _.random(0, @level) > 0
				block = new Block(@board, x, y)
				@blocks.push(block)




new Breakout()

