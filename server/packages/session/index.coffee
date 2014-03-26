
# # Session
# 
# Various means for dealing with sessions.

# ## Implements hook `auditKeys`
exports.$auditKeys = (req) ->
	
	# Session ID.
	session: req.session.id if req.session?

# ## Implements hook `socketAuthorizationMiddleware`
exports.$socketAuthorizationMiddleware = ->

	label: 'Load session'
	middleware: [
	
		(req, res, next) ->
			
			req.http.loadSessionFromRequest(
				req
			
			).then((session) ->
				req.session = session
				next()
				
			).catch next
			
	]

# ## Implements hook `socketRequestMiddleware`
exports.$socketRequestMiddleware = ->

	label: 'Join channel for socket'
	middleware: [
	
		(req, res, next) ->
			
			req.socket.join session.id if session?
				
			next()
			
	]
