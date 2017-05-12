senseJoystick = require 'sense-joystick'
senseLeds = require 'sense-hat-led'
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
	return (HEIGHT - x) * WIDTH + y

class Actor
	constructor: (@colour) ->
	getColour: -> @colour

class Player extends Actor
	constructor: ->
		super(BLUE)
		@position = position(0,4)

class Block extends Actor
	constructor: (x,y) ->
		super(RED)
		@position = position(0,4)

class Ball extends Actor
	constructor: ->
		super(GREEN)
		@position = position(1,4)

class Board
	constructor: ->
		@ledMatrix = _.times(HEIGHT * WIDTH, BLACK)
		@update()

	add: (actor, x, y) ->
		if not (actor instanceof Actor)
			throw new Error("Adding a non actor #{actor}")
		pos = position(x,y)
		if @ledMatrix[pos] isnt BLACK
			return false
		@ledMatrix[pos] = actor.getColour()
		@update()
		return true
	update: ->
		senseLeds.setPixels(@ledMatrix)


class Breakout
	constructor = ->
		@board = new Board()
		@level = 1
		@generateLevel()
		@blocks = []
		@player = new Player()
		@ball = new Ball()
		@board.add(@player)
		@board.add(@ball)


	generateLevel = ->
		for x in [0...4]
			for y in [0...WIDTH] when _.random(0, level) > 0
				block = new Block(x, y)
				@board.add(block)
				@blocks.push(block)




new Breakout()

