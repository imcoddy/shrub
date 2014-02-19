
crypto = require 'server/crypto'
passport = require 'passport'

exports.$endpoint = (req, fn) -> fn null, req.user

exports.$httpMiddleware = (http) ->

	{models: User: User} = require 'server/jugglingdb'
	
	LocalStrategy = require("passport-local").Strategy
	
	passport.use new LocalStrategy (username, password, done) ->
		
		filter = where: name: username
		
		User.findOne filter, (error, user) ->
			return done error if error?
			
			if user?
				
				User.hashPassword password, user.salt, (error, passwordHash) ->
					return done error if error?
					return done() unless user.passwordHash is passwordHash
					
					crypto.decrypt user.email, (error, decryptedEmail) ->
						return done error if error?
						
						user.email = decryptedEmail
					
						done null, user.redactFor user
			
			else
				
				done()
	
	passport.serializeUser (user, done) -> done null, user.id
	
	passport.deserializeUser (id, done) ->
		
		User.find id, (error, user) ->
			return done error if error?
			
			crypto.decrypt user.email, (error, decryptedEmail) ->
				return done error if error?
				
				user.email = decryptedEmail
			
				done null, user.redactFor user
	
	label: 'Load user using passport'
	middleware: [
	
		passport.initialize()
		passport.session()
		(req, res, next) ->
			
			req.user ?= new User()
			
			next()
		
	]

exports.$models = (schema, options) ->
	
	(require 'client/modules/packages/user').$models schema
	
	User = schema.models['User']
	
	User.randomHash = (fn) ->
		return fn new Error(
			"No crypto support."
		) unless options.cryptoKey?
		
		require('crypto').randomBytes 24, (error, buffer) ->
			return fn error if error?
			
			fn null, require('crypto').createHash('sha512').update(
				options.cryptoKey
			).update(
				buffer.toString()
			).digest 'hex'
	
	User.hashPassword = (password, salt, fn) ->
		return fn new Error(
			"No crypto support."
		) unless options.cryptoKey?
		
		require('crypto').pbkdf2 password, salt, 20000, 512, fn
	
exports.$socketMiddleware = (http) ->
	
	{models: User: User} = require 'server/jugglingdb'
	
	label: 'Load user using passport'
	middleware: [
	
		(req, res, next) ->
			
			req[method] = require('http').IncomingMessage.prototype[method] for method in [
				'login', 'logIn'
				'logout', 'logOut'
				'isAuthenticated', 'isUnauthenticated'
			]
			
			next()
			
		passport.initialize()
		passport.session()
		
		(req, res, next) ->
			
			req.passport = req._passport.instance
			
			req.user ?= new User()
			
			next()
	
	]

exports[path] = require "packages/user/#{path}" for path in [
	'forgot', 'login', 'logout', 'register', 'reset'
]