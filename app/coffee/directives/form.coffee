$module.directive 'shrubForm', [
	'$compile', '$q', 'forms', 'require'
	($compile, $q, forms, require) ->
		
		link: (scope, element, attrs) ->
			
			formKey = attrs['shrubForm']
			form = scope[formKey]
			
			# Hacking out the scope, gotta be a nicer way to do this.
			$form = angular.element '<form>'
			
			# Create the form element.
			$form = angular.element(
				'<form>'
			).attr(
				
				# Set submit handler, if any
				'data-ng-submit': "#{formKey}.submit.handler()"
				
				# Default method to POST.
				method: $form.attr('method') ? 'POST'
			
			).addClass formKey
			
			# Build the form fields.
			for name, field of form
				continue unless field.type?
				
				$wrapper = angular.element '<div>'
				$wrapper.append $field = switch field.type
					
					when 'email', 'password', 'text'
						$wrapper.append(
							angular.element('<label>').text field.title
						) if field.title?
						
						$input = angular.element(
							'<input type="' + field.type + '">'
						).attr(
							name: name
							'data-ng-model': name
						)
						
						$input.attr 'required', 'required' if field.required
						
					when 'submit'
					
						$input = angular.element(
							'<input type="submit">'
						)
						$input.attr 'value', field.title ? "Submit"
						$input.addClass 'btn'
						
				$form.append $wrapper
			
			# Add hidden form key to allow server-side interception/processing.
			$formKeyElement = angular.element '<input type="hidden"/>'
			$formKeyElement.attr name: 'formKey', value: formKey
			$form.append $formKeyElement
			
			# Insert and compile the form element.
			element.append $form
			$compile($form) scope
			
			# Register the form in the system.
			forms.register formKey, scope, $form
			
			# Guarantee a submit handler.
			(form.submit ?= {}).handler ?= -> $q.when true
			
]

