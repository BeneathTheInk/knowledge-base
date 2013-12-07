mongoose = require "mongoose"
async = require "async"
util = require "../util"

questionSchema = mongoose.Schema {
	last_updated: Date
	created: Date

	question: String
	details: String
	owner: mongoose.Schema.Types.ObjectId
	public: Boolean
	shortid: String
	handle: String
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

module.exports =
app.collections.questions =
Questions =
global.Questions = mongoose.model 'Question', questionSchema