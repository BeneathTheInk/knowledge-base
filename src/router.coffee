_ = require "underscore"
express = require "express"
http = require "http"
RedisStore = require('connect-redis')(express)
nunjucks = require "nunjucks"
lessm = require 'less-middleware'
auth = require "./auth"
fs = require "fs"
path = require "path"

# initiate express
router =
app.express = express()
app.express.enable "trust proxy"

# create a http server
server =
app.server = http.createServer(router)

### MIDDLEWARE ###
if app.env is "production"
	router.use(express.compress())

if app.env is "development"
	router.use(express.logger('dev'))
		.use(express.errorHandler())

router.use(express.cookieParser())
	.use(express.json())
	.use(express.urlencoded())
	.use(express.query())
	.use(express.session
		store: new RedisStore(client: app.redis, ttl: 14 * 24 * 60 * 60) # 2 weeks
		key: "bti.session"
		secret: "K6ASkWLB86QjFP1b7nTd219JZforSKn1"
		cookie: maxAge: 14 * 24 * 60 * 60 * 1000 # 2 weeks
		proxy: true
	)
	.use(lessm
		src: app.path "styles"
		dest: app.path "public/css"
		prefix: "/css"
		compress: app.env is "production"
		yuicompress: true
		once: app.env is "production"
		sourceMap: app.env is "development"
		# debug: app.env is "development"
	)
	
# Nunjucks (templating)
nunjucks.configure app.path('views'),
	express: router
	watch: true

# custom res.render
router.use (req, res, next) ->
	# allows any middleware to attach data to template
	locals = $req: req
	res.local = (key, val) ->
		if _.isObject(key) then _.each key, (k, v) -> res.local k, v
		return unless _.isString(key) and key isnt ""
		locals[key] = val
		return res

	njrender = res.render
	res.render = (name, data = {}) ->
		if path.extname(name) is "" then name = name + ".html"
		tpldata = _.extend {}, router.locals, locals, data
		njrender.call res, name, tpldata

	next()

# last of the middleare
router.use express.static app.path "public"
router.use auth
router.use router.router

# load in all routes
routesDir = path.join __dirname, "routes"
fs.readdirSync(routesDir).forEach (file) ->
	if _.contains [ ".js", ".coffee" ], path.extname(file)
		require path.join routesDir, file

# prepare for launch
app.ready ->
	# fire up the server
	port = process.env.PORT
	server.listen port, ->
		console.info "Express listening on port #{port}."
		console.info "Ready for HTTP Connections...\n"
