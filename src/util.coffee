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

# STRING GENERATION
crypto = require "crypto"

exports.RAND_ALPHA_UPPER = ["A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z"]
exports.RAND_ALPHA_LOWER = ["a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z"]
exports.RAND_NUMERIC = ["0","1","2","3","4","5","6","7","8","9"]
exports.RAND_ALPHA_NUMERIC = exports.RAND_NUMERIC.concat exports.RAND_ALPHA_UPPER, exports.RAND_ALPHA_LOWER
exports.RAND_HEX = exports.RAND_NUMERIC.concat exports.RAND_ALPHA_LOWER.slice 0, 6

exports.randId = (n, list) ->
	n ?= 8
	list ?= exports.RAND_ALPHA_NUMERIC
	id = ""
	rand_nums = crypto.randomBytes(n).toString("hex").match(/.{2}/g)
	_.each rand_nums, (h) ->
		i = parseInt(h, 16) / 256 # 0 <= i < 1
		r = Math.floor(i * list.length)
		id += list[r]
	return id

Number.prototype.toBase = (K) ->
	num = this * 1
	digits = []
	
	while num isnt 0
		remainder = num % K
		num = (num - remainder) / K
		digits.unshift remainder

	return digits

Number.prototype.toBase62 = () ->
	list = exports.RAND_ALPHA_NUMERIC
	_.map(this.toBase(62), (n) -> list[n]).join("")

# instance unique ids
# does not scale, use UUID or ObjectIds
lastTimestamp = null
counter = 0
exports.uniqueId = () ->
	ts = Date.now().toBase62()

	if lastTimestamp isnt ts
		counter = 0
		lastTimestamp = ts
	
	counter++
	cnt = counter.toBase62()
	while cnt.length < 3 then cnt = 0 + cnt
	return ts + cnt

# quick md5 in hex format
exports.md5_hex = (str) -> crypto.createHash("md5").update(str).digest("hex")

# TIMER
exports.TIMER_UNIT_CONVERSION = { milliseconds: 1, seconds: 1000, minutes: 60*1000 }
exports.TIMER_UNIT_ALIASES =
	milliseconds: [ "milliseconds", "ms", "msec" ]
	seconds: [ "seconds", "s", "sec" ]
	minutes: [ "minutes", "min" ]

exports.timer = ->
	t = new Date
	(unit, precision = 2) ->
		f = new Date - t
		key = unit.trim().pluralize()
		as = null

		_.some exports.TIMER_UNIT_ALIASES, (v, a) -> as = a if _.contains(v, key)
		cvt = exports.TIMER_UNIT_CONVERSION[as]

		if cvt? then return (f / cvt).round(precision) + unit
		else return f

# VARIABLE TYPE CHECK
exports.isType = (val, types) ->
	special = {
		"regex": _.isRegExp,
		"array": _.isArray,
		"date": _.isDate,
		"mixed": () -> return true }

	if _.isArray types
		return _.some types, (type) ->
			return exports.isType val, type # Recursive!

	else if _.isString types
		types = types.toLowerCase()
		if _.has(special, types) then return special[types](val)
		else return typeof val is types

	else
		type = typeof val
		_.some _.omit(special, "mixed"), (fnc, t) ->
			if fnc(val) then return type = t
		return type

# instead of true/false, throws an error
exports.check = (val, types) ->
	unless _.isArray(types) or _.isString(types)
		throw new Error "Expecting array or string for type."

	unless exports.isType val, types
		throw new Error "Variable is not the expected type."

# STRINGS TO OBJECTIDS
exports.strToId = (str) ->
	if _.isString(str) and /[a-f0-9]{24}/i.test(str)
		if app.isServer then {ObjectID} = require "mongodb"
		else ObjectID = require "../client/lib/objectid"
		return new ObjectID str
	else return str

# Account permission helper
perms = [ "guest", "basic", "advanced", "pro", "business", "admin", "super", "root" ]
exports.permission = (level, user) ->
	if user is true
		if _.isNumber(level) then return perms[level]
		else if _.isString(level)
			i = _.indexOf(perms, level)
			if i > -1 then return i
		else unless level? then return _.clone(perms)
	else
		# server needs to retrieve async so do it for us
		unless user? and _.isObject(user)
			throw new Error "Expecting user object for second argument."

		uperm = user.permission || 0
		if _.isNumber(level) then return uperm >= level
		else if _.isString(level)
			i = _.indexOf(perms, level)
			return if i > -1 then uperm >= i else false
		else return uperm