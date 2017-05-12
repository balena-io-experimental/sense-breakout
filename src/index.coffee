# senseJoystick = require 'sense-joystick'
# senseLeds = require 'sense-hat-led'
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
	constructor: (@colour, @position) ->

class Player extends Actor
	constructor: ->
		super(BLUE, position(0, 4))

class Block extends Actor
	constructor: (x,y) ->
		super(RED, position(x, y))

class Ball extends Actor
	constructor: ->
		super(GREEN, position(1, 4))

class Board
	constructor: ->
		@ledMatrix = _.times(HEIGHT * WIDTH, _.constant(BLACK))
		@update()

	add: (actor) ->
		if not (actor instanceof Actor)
			throw new Error("Adding a non actor #{actor}")
		pos = actor.position
		if not _.isEqual(@ledMatrix[pos], BLACK)
			return false
		@ledMatrix[pos] = actor.colour
		@update()
		return true

	update: ->
		senseLeds.setPixels(@ledMatrix)


class Breakout
	constructor: ->
		@board = new Board()
		@level = 1
		@blocks = []
		@player = new Player()
		@ball = new Ball()
		@board.add(@player)
		@board.add(@ball)
		@generateLevel()


	generateLevel: ->
		for x in [0...4]
			for y in [0...WIDTH] when _.random(0, @level) > 0
				block = new Block(x, y)
				@board.add(block)
				@blocks.push(block)




new Breakout()

