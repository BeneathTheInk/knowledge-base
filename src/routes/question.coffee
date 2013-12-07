

app.express.get "/question/:shortid/:handle?", (req, res) ->

	Questions.findOne shortid: req.param("shortid"), (err, question) ->
		if err? then return next err
		else unless question? then return res.render "404"

		handle = req.param "handle"
		if handle? and handle isnt "" and question.handle isnt handle
			return res.render "404"

		question.getOwner (err, owner) ->
			if err? then return next err

			res.render "question", { question, owner, title: question.question }