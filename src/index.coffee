if process.env.RESIN is '1'
	senseJoystick = require 'sense-joystick'
	senseLeds = require 'sense-hat-led'
else
	senseLeds =
		setPixels: (arr) ->
			console.log('setting', arr)
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

position = (x, y) ->
	console.log('xy', x, y)
	console.log('(HEIGHT - x) * WIDTH + y', (HEIGHT - x) * WIDTH + y)
	return (HEIGHT - x) * WIDTH + y

class Actor
	constructor: (@board, @colour, @position) ->
		@board.add(this)
	move: ->

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
		for x in [0...4]
			for y in [0...WIDTH] when _.random(0, @level) > 0
				block = new Block(@board, x, y)
				@blocks.push(block)




new Breakout()

