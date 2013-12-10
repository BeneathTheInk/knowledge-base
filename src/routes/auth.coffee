_ = require "underscore"

pagetitle = "Sign In"

app.express.get "/signin", (req, res, next) ->
	res.render "signin", title: pagetitle

app.express.post "/signin", (req, res, next) ->
	doerror = (err) ->
		err = err.message if err instanceof Error
		res.render "signin", error: err, title: pagetitle

	unless _.isEmpty(req.query.u) then redirect = req.query.u
	else redirect = "/"

	req.signin req.body.user, req.body.pass, (err) ->
		if err? then doerror err
		else res.redirect redirect

app.express.get "/signout", (req, res, next) ->
	req.signout()
	unless _.isEmpty(req.query.u) then res.redirect req.query.u
	else res.redirect "/signin"