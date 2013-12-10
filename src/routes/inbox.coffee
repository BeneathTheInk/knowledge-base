_ = require "underscore"
util = require "../util"

app.express.get "/inbox", (req, res, next) ->
	return res.redirect "/signin" unless req.user?
	user = req.user

	query = { owner: user._id }
	if util.permission("admin", user)
		query = $or: [ query, { answer: null } ]

	Questions
		.find(query)
		.sort({ created: 'desc' })
		.exec (err, questions) ->
			if err? then console.error err.stack
			else
				all = []
				unanswered = []
				answered = []

				_.each questions, (q) ->
					if q.answer? then answered.push q
					else
						all.push q
						if q.owner.toString() is user._id.toString()
							unanswered.push q

				res.render "inbox", { title: "Inbox", unanswered, answered, all }