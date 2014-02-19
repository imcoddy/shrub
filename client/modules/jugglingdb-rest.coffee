
###

Socket.IO adapter proxy for [JugglingDB](https://github.com/1602/jugglingdb).

This adapter forwards all adapter commands through a socket, to be run by the
database server.

###

i8n = require 'inflection'

class SocketAdapter
	
	constructor: (@schema, @$http) ->
	
	# DRY.
	promiseCallback = (fn, promise) -> promise.then(
		({data}) -> fn null, data
		({data}) -> fn new Error data.message
	)
		
	# Translate a query object into a REST query.
	translateQuery = (query) ->
		
		params = []
		params.push "limit=#{query.limit}" if query.limit?
		params.push "order=#{query.order}" if query.order?
		params.push "skip=#{query.skip}" if query.skip?
		if query.where? and Object.keys(query.where).length
			for key, value of query.where
				params.push "where[#{key}]=#{value}"
		params.join '&'
	
	# Connect/disconnect are nops, gotta invoke the callback though.
	[
		'connect', 'disconnect'
	].forEach (prop) => @::[prop] = (fn) -> fn()
	
	# These adapter methods aren't necessary to run on the client. They are
	# responsible for underlying schema management and only make sense when
	# the adapter is actually touching the database e.g. server-side.
	[
		'define', 'defineForeignKey', 'possibleIndexes', 'updateIndexes'
		
		# and our ugly duckling.
		'transaction'
	].forEach (prop) => @::[prop] = ->
	
	all: (model, query, fn) ->
		
		{collection} = @schema.resourcePaths model
		query = translateQuery query
		
		promiseCallback fn, @$http.get "#{@schema.settings.apiRoot}/#{collection}?#{query}"
	
	count: (model, fn) ->
	
		{collection} = @schema.resourcePaths model
		
		promiseCallback fn, @$http.get "#{@schema.settings.apiRoot}/#{collection}/count"
	
	create: (model, data, fn) ->
	
		{collection} = @schema.resourcePaths model
		
		promiseCallback fn, @$http.post "#{@schema.settings.apiRoot}/#{collection}", data
	
	destroy: (model, id, fn) ->
		
		{resource} = @schema.resourcePaths model
		
		promiseCallback fn, @$http.delete "#{@schema.settings.apiRoot}/#{resource}/#{id}"
	
	destroyAll: (model, fn) ->
	
		{collection} = @schema.resourcePaths model
		
		promiseCallback fn, @$http.delete "#{@schema.settings.apiRoot}/#{collection}"
	
	exists: (model, id, fn) ->
	
		{resource} = @schema.resourcePaths model
		
		promiseCallback fn, @$http.get "#{@schema.settings.apiRoot}/#{resource}/#{id}/exists"
	
	find: ->
	
	save: (model, data, fn) ->
	
		{id} = data
		{resource} = @schema.resourcePaths model
		
		if id?
			promiseCallback fn, @$http.put "#{@schema.settings.apiRoot}/#{resource}/#{id}", data
		else
			@create model, data, fn
	
	updateAttributes: (model, id, data, fn) ->
		data.id = id
		@save model, data, fn
	
	updateOrCreate: @::save
	
# Initialization method; instantiate the SocketAdapter.
exports.initialize = (schema) ->
	{$http, inflection} = schema.settings
	schema.adapter = new SocketAdapter schema, $http, inflection
