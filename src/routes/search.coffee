async = require "async"

app.express.get "/search", (req, res, next) ->
	search = req.query.s ? ""
	
	app.search.query(search).end (err, results) ->
		if err? then return next err
		
		results ?= []

		async.map results, (id, cb) ->
			Questions.findById id, cb
		, (err, questions) ->
			if err? then next err
			else res.render "search", { search_term: search, results: questions, title: "Search Results" }