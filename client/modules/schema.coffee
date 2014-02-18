
## The database schema

access = require 'access'
i8n = require 'inflection'

exports.define = (Schema, adapter, options = {}) ->
	
	schema = new Schema adapter, options
	
	# Translate model names to REST resource/collection paths.
	# 'CatalogEntry' -> ['catalog-entry', 'catalog-entries']
	schema.resourcePaths = (name) ->
	
		resource = i8n.underscore name
		resource = i8n.dasherize resource.toLowerCase()
		
		resource: resource
		collection: i8n.pluralize resource
	
	User = access.wrapModel schema.define 'User',
		
		email:
			type: String
			index: true
		
		name:
			type: String
			default: 'Anonymous'
			length: 24
			index: true
			
		passwordHash:
			type: String
		
		resetPasswordToken:
			type: String
			length: 128
			index: true
		
		salt:
			type: String
			length: 128
			
	User::hasPermission = (perm) -> true
	
	# TODO should be config, not hardcoded...	
	schema.root = '/api'

	schema