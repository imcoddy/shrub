
# # Example!
# 
# Define some routes, set a nav, show some stuff off!

# ## Implements hook `appRun`
exports.$appRun = -> [
	'ui/nav', 'ui/title'
	({setLinks}, {setSite}) ->
		
		setLinks [
			pattern: '/home', href: '/home', name: 'Home'
		,
			pattern: '/about', href: '/about', name: 'About'
		,
			pattern: '/user/register', href: '/user/register', name: 'Sign up'
		,
			pattern: '/user/login', href: '/user/login', name: 'Sign in'
		,
			pattern: '/user/logout', href: '/user/logout', name: 'Sign out'
		]
		
		setSite 'Shrub'
]

exports[path] = require "./#{path}" for path in [
	'about', 'home'
]
