
exports.$service = [
	'$q', 'comm/rpc', 'core/schema'
	($q, rpc, schema) ->
		
		user = new schema.User
		
		isLoggedIn: (fn) -> @load().then (user) -> fn user.id? 
			
		login: (method, username, password) ->
			
			rpc.call(
				'user.login'
				method: method
				username: username
				password: password
			).then(
				(O) ->
					user.fromObject O
					user
			)

		logout: ->
			
			rpc.call(
				'user.logout'
			).then(
				->
					user.fromObject (new schema.User).toObject()
					user
			)
		
		load: -> rpc.call('user').then (O) ->
			user.fromObject O
			user
		
]

exports.$serviceMock = [
	'$delegate', 'comm/socket'
	($delegate, socket) ->
	
		socket.catchEmit 'rpc://user', (data, fn) ->
			fn result: name: 'Anonymous'
		
		$delegate
		
]

exports.$endpoint = (req, fn) -> fn null, req.user

exports[path] = require "packages/user/#{path}" for path in [
	'forgot', 'login', 'logout', 'register', 'reset'
]