# dependencies
_ = require "underscore"
require "sugar"
path = require "path"
{EventEmitter} = require "events"
util = require "./util"

class Application extends EventEmitter

	constructor: ->
		# app state
		@state = "init"
		@initTimer = new Date # date cache for the *rough* time of launch

		# app environment
		@env = process.env.NODE_ENV
		@dir = process.cwd()
		@isServer = true
		@isClient = false

	# starts up the app
	start: () ->
		if @state is "error"
			console.warn "App failed to initiate."
		else
			console.info "App initiated successfully in #{new Date - @initTimer}ms.\n"
			@emit @state = "ready" # make it ready
		@start = -> # prevent re-access
		return @ # chaining

	# tell the app to wait on a async request
	wait: (fn) ->
		unless @_wait_fn?
			@_wait_fn = util.AsyncWait => @start()

		return @_wait_fn fn

	# call a function now or on ready
	ready: (fn) ->
		if @state is "ready" then fn.call @
		else @once "ready", fn
		return @ # chaining

	# put app in an error state
	error: (err) ->
		err = err.stack if err instanceof Error and err.stack?
		err = err.toString() unless _.isString err
		console.error "Exception preventing startup:\n" + err
		@_lastError = err
		@state = "error"
		return @ # chaining

	# convenience method for turning a relative path into an absolute path
	path: (args...) ->
		args = _.compact _.flatten args
		args.unshift @dir
		path.resolve.apply path, args

	# convenience method for turning an absolute path into a relative path
	relative: (to, lead = false) -> (if lead then "/" else "") + path.relative @dir, to

app =
global.app =
module.exports = new Application

# LOAD PARTS #
require "./setup"	# MongoDB + Redis
require "./router"	# Express + Nunjucks