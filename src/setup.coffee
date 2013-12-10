_ = require "underscore"
fs = require "fs"

### MONGO ###

mongoose = require 'mongoose'
url = require "url"

mongo_url = process.env.MONGO_URL
unless mongo_url? then throw new Error "Missing mongo URL."

mongoose.connect mongo_url
app.db = mongoose.connection

app.db.on "error", (e) ->
	if app.state is "ready" then console.error e.stack
	else app.error e

app.db.once "open", app.wait ->
	purl = url.parse mongo_url
	console.info "Connected to mongo database #{app.db.db.databaseName} at #{purl.host}."

### AUTH CONNECTION ###
# This is a terrible way to set this up.
# Auth should be moved to its own server.
{MongoClient} = require "mongodb"
MongoClient.connect "mongodb://localhost:27017/dashboard", app.wait (err, db) ->
	if err then return app.error err
	app.users = db.collection "users"

### COLLECTIONS / MODELS ###

app.collections = {}
app.loadDir "src/models" # load all models

### REDIS ###

redis = require "redis"

rport = process.env.REDIS_PORT ? 6379
rhost = process.env.REDIS_HOST ? "localhost"
rauth = process.env.REDIS_AUTH ? null

rdb = parseInt process.env.REDIS_DB, 10
if !rdb? or isNaN(rdb) then rdb = 0

app.redis = redis.createClient rport, rhost, auth_pass: rauth
app.redis.on "ready", app.wait -> console.info "Connected to redis database #{rdb} at #{rhost}:#{rport}."
app.redis.on "error", (e) -> console.error e

# switch databases and flush on start
app.redis.multi().select(rdb).flushdb().exec app.wait()

### REDS ###

reds = require "reds"
reds.createClient = -> return app.redis
app.search = reds.createSearch "questions"