mongoose = require "mongoose"
async = require "async"
util = require "../util"

questionSchema = mongoose.Schema {
	last_updated: Date
	created: Date

	question: String
	details: String
	owner: mongoose.Schema.Types.ObjectId

	answer: String
	answered_by: mongoose.Schema.Types.ObjectId
	answered_on: Date

	shortid: String
	handle: String
	views: { type: Number, default: 0 }
	tags: { type: Array, default: [] }
	public: { type: Boolean, default: false }
}, { collection: "questions" }

# get owner model method
questionSchema.methods.getOwner = (cb) ->
	app.users.findOne _id: this.owner, cb

# set defaults
questionSchema.pre "save", (next) ->
	unless @created? then @created = new Date
	@last_updated = new Date

	# always set the handle, just in case it was modified
	@handle = @question.truncateOnWord(40, 'right', '').parameterize()

	# if there's an answer, add an answered date
	if @answer? and !@answered_on? then @answered_on = new Date
	else unless @answer? then @answered_on = undefined

	return next() unless @isNew

	@public ?= false
	@shortid = util.randId 6

	canSave = false
	async.whilst(
		-> not canSave
		(cb) =>
			Questions.count shortid: @shortid, (err, count) =>
				if err? then return cb err
				if count isnt 0 then @shortid = util.randId 6
				else canSave = true
				cb()
		next
	)

addToSearchDB = (q, next) ->
	return next() unless q.public
	id = q._id.toString()

	# attempt remove
	app.search.remove id, (err) ->
		if err? then return next err

		# put together all of the necessary search text
		parts = [ q.question, q.tags.join(" "), q.details, q.answer ].join " "
		app.search.index parts, id, next

# update search database
questionSchema.pre "save", (next) -> addToSearchDB @, next

module.exports =
app.collections.questions =
Questions =
global.Questions = mongoose.model 'Question', questionSchema

# on start cycle through all public questions and add make them searchable
waitr = app.wait()
Questions.find public: true, (err, questions) ->
	if err? then return app.error err
	async.each questions, addToSearchDB, (err) ->
		if err? then app.error err
		else console.info "Added #{questions.length} questions to the search index."
		waitr()