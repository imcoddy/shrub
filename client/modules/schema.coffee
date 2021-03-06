
# # JugglingDB

i8n = require 'inflection'
pkgman = require 'pkgman'
{Schema} = require 'promised-jugglingdb'

# Translate model names to REST resource/collection paths.
# `'CatalogEntry'` -> `['catalog-entry', 'catalog-entries']`
Schema::resourcePaths = (name) ->

	resource = i8n.dasherize(i8n.underscore name).toLowerCase()
	
	resource: resource
	collection: i8n.pluralize resource

# ## define
# 
# Define the JugglingDB schema.
exports.define = (adapter, options = {}) ->
	
	schema = new Schema adapter, options
	
	# ## schema.definePackageModels
	# 
	# Let packages define JugglingDB models.
	schema.definePackageModels = ->
		
		# Invoke hook `models`.
		# Allows packages to create models in the database schema.
		pkgman.invoke 'models', schema
	
		# Invoke hook `modelsAlter`.
		# Allows packages to alter any models defined.
		pkgman.invoke 'modelsAlter', schema.models, schema
		
	schema
