_ = require "underscore"

### MONGO ###

{MongoClient} = require "mongodb"
url = require "url"

mongo_url = process.env.MONGO_URL
unless mongo_url? then throw new Error "Missing mongo URL."

MongoClient.connect mongo_url, app.wait (err, db) ->
	if err then return app.error err
	app.db = db
	purl = url.parse mongo_url
	console.info "Connected to mongo database #{db.databaseName} at #{purl.host}."
	app.emit "database", db

### AUTH CONNECTION ###
# This is a terrible way to set this up.
# Auth should be moved to its own server.
MongoClient.connect "mongodb://localhost:27017/dashboard", app.wait (err, db) ->
	if err then return app.error err
	app.users = db.collection "users"

### COLLECTIONS ###

app.collections = {}
app.collection = (name) ->
	unless app.db?
		throw new Error "Cannot call app.collection until database is ready."

	if _.has(app.collections, name) then return app.collections[name]
	
	col = app.db.collection name

	app.collections[name] = col
	app.db[name] = col unless _.has(app.db, name) or app.db[name]?

	return col

### REDIS ###

redis = require "redis"

rport = process.env.REDIS_PORT ? 6379
rhost = process.env.REDIS_HOST ? "localhost"
rauth = process.env.REDIS_AUTH ? null

rdb = parseInt process.env.REDIS_DB, 10
if !rdb? or isNaN(rdb) then rdb = 0

app.redis = redis.createClient rport, rhost, auth_pass: rauth
app.redis.select rdb, app.wait()
app.redis.on "ready", app.wait -> console.info "Connected to redis database #{rdb} at #{rhost}:#{rport}."
app.redis.on "error", (e) -> console.error e

### REDS ###

reds = require "reds"
reds.createClient = -> return app.redis