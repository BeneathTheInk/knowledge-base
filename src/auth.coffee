_ = require "underscore"
util = require "./util"

# auth middleware
module.exports = (req, res, next) ->

	# signin middleware
	req.signin = (user, pass, cb) ->
		unless _.isFunction(cb) then cb = ->

		_.defer ->
			# must pass both username and password
			unless user? and pass?
				return cb new Error "Both username and password are required." 

			# md5 password if it isn't already
			unless /[a-f0-9]{32}/i.test(pass)
				pass = util.md5_hex pass

			# find by username or email
			app.users.findOne { $or: [ { username: user }, { email: user } ] }, (err, user) ->
				if err? then return cb err
				else unless user? and user.password is pass
					return cb new Error "Incorrect username or password."

				# save the login_key and userid to session
				req.session.login_key = user.login_key
				req.session.userid = user._id.toString()

				cb()

	# signout middleware
	req.signout = ->
		delete req.session.login_key
		delete req.session.userid

	# check for signed in user
	{login_key, userid} = req.session
	return next() unless login_key? and userid?
	
	app.users.findOne { _id: util.strToId(userid) }, (err, user) ->
		if err? then return next()
		unless user? and user.login_key is login_key then return next()

		# help out other routes with the user
		req.user = user
		res.local "user", user
		next()