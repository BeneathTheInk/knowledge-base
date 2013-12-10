async = require "async"

app.express.get "/", (req, res, next) ->
	recent = []
	most_viewed = []

	async.parallel [
		(cb) ->
			Questions.find({ answer: { $exists: true }})
				.sort({ answered_on: -1 })
				.limit(5)
				.exec (err, questions) ->
					recent = questions ? []
					cb err

		(cb) ->
			Questions.find()
				.sort({ views: -1 })
				.limit(5)
				.exec (err, questions) ->
					most_viewed = questions ? []
					cb err

	], (err) ->
		if err? then next err
		else res.render "home", { recent, most_viewed }