_ = require "underscore"

# Waits on several async callbacks to be called and
# then calls onEmpty. Technically should be called
# at least once, otherwise acts as a deferred call
# to onEmpty. Resusable.
exports.AsyncWait = (onEmpty) ->
	counter = 0

	callback = (cb) ->
		counter++
		called = false
		
		return ->
			return if called
			called = true

			counter--
			cb.apply @, arguments if typeof cb is "function"
			
			onEmpty() if counter <= 0 and typeof onEmpty is "function"
			return

	_.defer callback()

	return callback