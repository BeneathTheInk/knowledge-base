_ = require "underscore"
nodemailer = require "nodemailer"

# get the username and password
user = process.env.MAILGUN_USER
pass = process.env.MAILGUN_PASS
unless user? and pass? then throw new Error "Missing Mailgun username and password."

# set up mail transport
app.mailgun =
transport = nodemailer.createTransport "Mailgun",
	auth: { user, pass }

# from email
from = "Beneath the Ink Knowledge Base <noreply@beneaththeink.com>"

# public api
app.mail = (to, subject, text, cb) ->
	if _.isArray(to) then to = to.join(", ")

	data = { from, to, subject, text }
	transport.sendMail data, cb