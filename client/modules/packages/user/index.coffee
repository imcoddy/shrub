
# # User
# 
# User operations, model, etc.

Promise = require 'bluebird'

config = require 'config'

# ## Implements hook `models`
exports.$models = (schema) ->
	
	# Define the User model.
	User = schema.define 'User',
		
		# Email address.
		email:
			type: String
			index: true
		
		# Case-insensitivized name.
		iname:
			type: String
			length: 24
			index: true
			
		# Name.
		name:
			type: String
			default: 'Anonymous'
			length: 24
			
		# Hash of the plaintext password.
		passwordHash:
			type: String
		
		# A token which can be used to reset the user's password (once).
		resetPasswordToken:
			type: String
			length: 48
			index: true
		
		# A 512-bit salt used to cryptographically hash the user's password.
		salt:
			type: String
			length: 128
			
	# Temporary... secure by default.
	# `TODO`: Access control structure.
	User::hasPermission = (perm) -> false
	User::isAccessibleBy = (user) -> false
	
authenticatedModel = (User, Model, name) ->
	
# ## Implements hook `modelsAlter`
exports.$modelsAlter = (models) ->
	
	{User} = models
	
	# Implement all the built-in model methods as authenticated versions, which
	# take a user.
	for name, Model of models
		do (name, Model) ->
	
			validateUser = (user) ->
				
				new Promise (resolve, reject) ->
				
					return resolve() if user instanceof User
						
					error = new Error "Invalid user."
					error.code = 500
					reject error
			
			checkPermission = (user, perm) ->
			
				return if user.hasPermission perm
					
				error = new Error "Forbidden."
				error.code = 403
				throw error
					
			Model.authenticatedAll = (user, params) ->
				
				validateUser(user).then(->
					checkPermission user, "schema:#{name}:all"
				
				).then(->
					Model.all params
				
				).then (models) ->
					return models if models.length > 0
					
					error = new Error "Collection not found."
					error.code = 404
					Promise.reject error
			
			Model.authenticatedCount = (user) ->
				
				validateUser(user).then(->
					checkPermission user, "schema:#{name}:count"
				
				).then -> Model.count()
				
			Model.authenticatedCreate = (user, properties) ->
		
				validateUser(user).then(->
					checkPermission user, "schema:#{name}:create"
				
				).then -> Model.create properties
		
			Model.authenticatedDestroy = (user, id) ->
			
				validateUser(user).then(->
					checkPermission user, "schema:#{name}:create"
				
				).then(->
					Model.authenticatedFind user, id
				
				).then (model) ->
					return model.destroy() if model.isDeletableBy user
						
					if model.isAccessibleBy user
						error = new Error "Access denied."
						error.code = 403
					else
						error = new Error "Resource not found."
						error.code = 404
					
					Promise.reject error
			
			Model.authenticatedDestroyAll = (user) ->
			
				validateUser(user).then(->
					checkPermission "schema:#{name}:destroyAll"
				
				).then -> Model.destroyAll()
				
			Model.authenticatedFind = (user, id) ->
		
				validateUser(user).then(->
					Model.find id
			
				).then (model) ->
					return model if model? and model.isAccessibleBy user
					
					error = new Error "Resource not found."
					error.code = 404
					Promise.reject error
			
			Model.authenticatedUpdate = (user, id, properties) ->
		
				validateUser(user).then(->
					Model.authenticatedFind user, id
				
				).then (model) ->
					if model.isEditableBy user
						return model.updateAttributes properties
						
					if model.isAccessibleBy user
						error = new Error "Access denied."
						error.code = 403
					else
						error = new Error "Resource not found."
						error.code = 404
					
					Promise.reject error
				
			Model::isAccessibleBy ?= (user) -> true
			Model::isEditableBy ?= (user) -> false
			Model::isDeletableBy ?= (user) -> false
			Model::redactFor ?= (user) -> Promise.resolve this
		
# ## Implements hook `service`		
exports.$service = -> [
	'rpc', 'schema', 'socket'
	({call}, {models: User: User}, socket) ->
		
		service = {}
		
		user = new User config.get 'user'
		
		# Log a user out if we get a socket call.
		logout = -> user.fromObject (new User).toObject()
		socket.on 'user.logout', logout
		
		# ## user.isLoggedIn
		# 
		# *Whether the current application user is logged in.*
		service.isLoggedIn = -> service.instance().id? 
			
		# ## user.login
		# 
		# *Log in with method and args.*
		# 
		# `TODO`: username and password are tightly coupled to local
		# strategy. Change that.
		service.login = (method, username, password) ->
			
			call(
				'user.login'
				method: method
				username: username
				password: password
			
			).then (O) ->
				user.fromObject O
				user

		# ## user.logout
		# 
		# *Log out.*
		service.logout = ->
			
			call(
				'user.logout'

			).then logout
		
		# ## user.instance
		# 
		# *Retrieve the user instance.*
		service.instance = -> user
		
		service
		
]

# ## Implements hook `serviceMock`
exports.$serviceMock = -> [
	'$delegate', 'socket'
	($delegate, socket) ->
		
		# ## user.fakeLogin
		# 
		# *Mock a login process.*
		# 
		# `TODO`: This will change when login method generalization happens.
		$delegate.fakeLogin = (username, password = 'password', id = 1) ->
			socket.catchEmit 'rpc://user.login', (data, fn) ->
				fn result: id: id, name: username
				
			$delegate.login 'local', username, password
			
		$delegate
	
]

exports[path] = require "./#{path}" for path in [
	'forgot', 'login', 'logout', 'register', 'reset'
]
