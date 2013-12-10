
app.express.get "/tag/:tag", (req, res) ->
	tag = req.param("tag").toLowerCase()

	Questions.find { tags: $in: [ tag ] }, (err, results) ->
		if err? then next err
		else res.render "tag", { results, tag, title: tag }