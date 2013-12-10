_ = require "underscore"
util = require "../util"
async = require "async"

pagetitle = "Ask a Question"

app.express.get "/ask", (req, res, next) ->
	res.render "ask", title: pagetitle

app.express.post "/ask", (req, res, next) ->
	doerror = (err) ->
		err = err.message if err instanceof Error
		res.render "ask", error: err, data: req.body, title: pagetitle

	unless req.user?
		return doerror "You must be signed in to ask a question."

	expecting = { "Question": "question" }
	return unless _.every expecting, (name, label) ->
		return true unless _.isEmpty req.body[name]
		doerror "The #{label} field is required."

	data = _.pick req.body, "question", "details"
	data.owner = req.user._id

	Questions.create data, (err, doc) ->
		if err? then return doerror err
		
		to = "info@beneaththeink.com"
		if app.env is "development" then to = req.user.email

		app.mail to, doc.question, """#{doc.details}\n\n---\nvia #{req.user.username}\nhttp://#{app.host}/question/#{doc.shortid}/#{doc.handle}"""
		
		res.redirect "/inbox?success=1"