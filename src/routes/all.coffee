

app.express.get "/all", (req, res, next) ->

	Questions.find(public: true).sort({ created: -1 }).exec (err, questions) ->
		if err? then next err
		else res.render "all", { questions, title: "All Questions" }