
# # Generate documentation
# 
# Various parts of the documentation are generated dynamically. This file
# parses the source files and generates the respective documentation files.

fs = require 'fs'

glob = require 'groc/node_modules/glob'

# Load the groc configuration and read all sources.
grocConfig = JSON.parse fs.readFileSync '.groc.json', encoding: 'utf8'

files = {}
for globExpression in grocConfig.glob
	files[file] = true for file in glob.sync globExpression
for globExpression in grocConfig.except
	delete files[file] for file in glob.sync globExpression

sources = {}
for filename of files
	
	raw = fs.readFileSync filename, encoding: 'utf8'
	lines = raw.split('\n').map (line) -> line.trim()
	
	commentLines = lines.map (line) ->
		if line.match /^\#\s.+/ then line else ''
	
	sources[filename] =
		raw: raw
		lines: lines
		commentLines: commentLines
	
# Generate hook documentation.
generateHookDocumentation = do ->
	
	markdown = """

# Hooks

Shrub implements message passing between packages through a hook system. Hooks
may be invoked with [pkgman.invoke()](./client/modules/pkgman.html), and are
implemented in packages by prefixing a `$` to the hook name.

For instance, if we are implementing a package and want to implement the
`httpListening` hook, our code would look like:

	exports.$httpListening = ->
		
		# Your code goes here...

A dynamically generated listing of hooks follows.


"""
	
	hookInformation = {}
	for filename, {commentLines} of sources
		
		for commentLine, index in commentLines
			
			# } Find the comment with the hook invocation, and retrieve the
			# } hook name.
			if matches = commentLine.match /^\#\sInvoke hook `([^`]+)`/
				
				# } Look ahead until we hit an empty line; all following lines
				# } until then are the hook description.
				description = ''
				hookName = matches[1]
				lookaheadIndex = index + 1
				while lookaheadLine = commentLines[lookaheadIndex]
					matches = lookaheadLine.match /^\#\s(.*)$/
					description += matches[1].trim() + ' '
					
					lookaheadIndex += 1
				
				# } Key what we've found by filename.
				(hookInformation[filename] ?= []).push
				
					description: description
					name: hookName
	
	# } Output the hook information.			
	alphabetical = Object.keys(hookInformation).sort()
	for filename in alphabetical
		hooks = hookInformation[filename]
		
		# } Top-level list: filenames
		markdown += "* [#{
			filename
		}](./#{
			filename.replace /(coffee|js)/, 'html'
		}):\n\n"
		
		# } Second-level list: hook names and descriptions.
		for {name, description} in hooks
			
			markdown += "\t* `#{
				name
			}` - #{
				description
			}\n\n"
		
	fs.writeFileSync "documentation/hooks.md", markdown

# Generate TODO documentation.
generateHookDocumentation = do ->
	
	markdown = """

# TODO

Shrub -- like any project -- always presents a path for improvement. This is
a dynamically generated listing of TODO items, each with a line of code
context.


"""
	
	todoInformation = {}
	for filename, {lines} of sources
		
		for line, index in lines
			
			# } Find the comment with the TODO, and retrieve the description.
			if matches = line.match /^\#\s(?:}\s+)?`TODO`:\s(.*)$/
			
				# } Look ahead until we hit an empty line; all following lines
				# } until then are the TODO description.
				description = matches[1] + ' '
				lookaheadIndex = index + 1
				while lookaheadLine = lines[lookaheadIndex]
					break unless (matches = lookaheadLine.match /^\#\s(.*)$/)?
					
					description += matches[1].trim() + ' '
					
					lookaheadIndex += 1
				
				# Look ahead until we find a non-comment. We'll use this as
				# context for the TODO item.
				while lines[lookaheadIndex].match /^(\#|$)/
					lookaheadIndex += 1
				
				(todoInformation[filename] ?= []).push
					
					context: lines[lookaheadIndex]
					description: description
				
	# } Output the TODO information.
	alphabetical = Object.keys(todoInformation).sort()
	for filename in alphabetical
		todos = todoInformation[filename]
		
		# } Top-level list: filenames
		markdown += "* ##[#{
			filename
		}](./#{
			filename.replace /(coffee|js)/, 'html'
		}):\n\n"
		
		# } Second-level list: TODO descriptions.
		for {context, description} in todos
			
			markdown += "\t* #{
				description
			}\n\n\t  `#{
				context
			}`\n\n"
		
	fs.writeFileSync "documentation/todos.md", markdown