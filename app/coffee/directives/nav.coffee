
$module.directive 'shrubNav', [
	'$location', 'me', 'nav', 'socket', 'title'
	($location, me, nav, socket, title) ->
	
		templateUrl: '/partials/nav.html'
		
		link: (scope, elm, attr) ->
		
			scope.title = title.page
			scope.links = nav.links
			scope.me = me
			
# Make sure we set active the first time, since angular-strap won't be ready.

			scope.$watch(
				-> scope.links()
				->
					path = $location.path()
					for link in scope.links()
					
						regexp = new RegExp "^#{link.pattern}$", ['i']
						link.active = if regexp.test path then 'active'
					
			)
			
]
