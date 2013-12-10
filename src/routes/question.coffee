_ = require "underscore"
util = require "../util"

app.express.get "/question/:shortid/:handle?", (req, res, next) ->

	Questions.findOne shortid: req.param("shortid"), (err, question) ->
		if err? then return next err
		else unless question? then return res.render "404"

		handle = req.param "handle"
		if handle? and handle isnt "" and question.handle isnt handle
			return res.render "404"

		# bump views and save
		question.views++
		question.save (err) ->
			if err? then return next err

			done = (err, answered_by) ->
				if err? then next err
				else res.render "question", { question, answered_by, title: question.question }

			if question.answered_by? then app.users.findOne _id: question.answered_by, done
			else done()

app.express.get "/question/:shortid/:handle/delete", (req, res, next) ->

	Questions.findOne shortid: req.param("shortid"), (err, question) ->
		if err? then return next err
		else unless question? then return res.render "404"

		handle = req.param "handle"
		if question.handle isnt handle then return res.render "404"
		url = "/question/#{question.shortid}/#{question.handle}"

		# redirect back to question if not signed in and not admin
		unless req.user? and util.permission("admin", req.user)
			return res.redirect url

		# delete!
		question.remove (err) -> res.redirect url

app.express.post "/question/:shortid/:handle?", (req, res, next) ->
	# redirect back to question if not signed in
	unless req.user? then return res.redirect req.url
	user = req.user

	Questions.findOne shortid: req.param("shortid"), (err, question) ->
		if err? then return next err
		else unless question? then return res.render "404"

		doerror = (err) ->
			err = err.message if err instanceof Error
			res.render "question", { error: err, data: req.body, question, title: question.question }

		isAdmin = util.permission "admin", user
		isOwner = question.owner.toString() is user._id.toString()
		unless isAdmin or isOwner then return doerror "You don't have permission to edit this question."
		if not isAdmin and question.answer? then return doerror "Once a question has been answered it cannot be edited."

		# first deal with question and details
		expecting = { "Question": "question" }
		return unless _.every expecting, (name, label) ->
			return true unless _.isEmpty req.body[name]
			doerror "The #{label} field is required."

		question.question = req.body.question
		question.details = req.body.details ? ""

		# next admin level stuff
		if isAdmin
			if _.isEmpty(req.body.answer) then question.answer = question.answered_by = undefined
			else
				question.answer = req.body.answer
				question.answered_by ?= user._id

			tags = req.body.tags?.split(",") ? []
			question.tags = _.chain(tags).invoke("trim").invoke("toLowerCase").compact().unique().value()

			question.public = not _.isEmpty req.body.public

		question.save (err) ->
			if err? then doerror err
			else res.redirect "/question/#{question.shortid}/#{question.handle}"