_ = require "underscore"

app.express.get "/inbox", (req, res) ->
	return res.redirect "/signin" unless req.user?

	app.collection("questions").find(owner: req.user._id.toString()).toArray (err, questions) ->
		if err? then console.error err.stack
		else
			unanswered = []
			answered = []

			_.each questions, (q) ->
				if q.answer? then answered.push q
				else unanswered.push q

			res.render "inbox", { title: "Inbox", unanswered, answered }