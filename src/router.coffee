_ = require "underscore"
express = require "express"
http = require "http"
RedisStore = require('connect-redis')(express)
nunjucks = require "nunjucks"

# initiate express
router =
app.express = express()
app.express.enable "trust proxy"

# create a http server
server =
app.server = http.createServer()

# middleware
router.use express.cookieParser()

if app.env is "production"
	router.use(express.compress())
		.use(express.bodyParser({ keepExtensions: true }))

if app.env is "development"
	router.use(express.logger('dev'))
		.use(express.errorHandler())
		.use(express.bodyParser())

router.use(express.session
		store: new RedisStore(client: app.redis, ttl: 14 * 24 * 60 * 60) # 2 weeks
		key: "bti.session"
		secret: "K6ASkWLB86QjFP1b7nTd219JZforSKn1"
		cookie: maxAge: 14 * 24 * 60 * 60 * 1000 # 2 weeks
		proxy: true
	)
	.use(express.query())
	.use(express.static(app.path "public"))

# Nunjucks (templating)
nunjucks.configure app.path('views'),
    express: router
    watch: true

# prepare for launch
app.ready ->
	# fire up the server
	port = process.env.PORT
	server.listen port, ->
		console.info "Express listening on port #{port}."
		console.info "Ready for HTTP Connections...\n"