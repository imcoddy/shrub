
# # Limiter
# 
# Define a TransmittableError for the limiter.

{TransmittableError} = require 'errors'

# Implement a TransmittableError to inform the user of limiter threshold
# passing..
class LimiterThresholdError extends TransmittableError
	
	constructor: (message, @time) -> super
	
	key: 'limiterThreshold'
	template: ":message You may try again :time."
	toJSON: -> [@key, @message, @time]

# ## Implements hook `transmittableError`
exports.$transmittableError = -> LimiterThresholdError
