_ = require "underscore"

pagetitle = "Ask a Question"

app.express.get "/ask", (req, res) ->
	res.render "ask", title: pagetitle

app.express.post "/ask", (req, res) ->
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
	data.owner = req.user._id.toString()
	data.public = false
	data.created = data.last_updated = new Date

	app.collection("questions").insert data, (err, docs) ->
		if err? then doerror err
		else res.send "success"