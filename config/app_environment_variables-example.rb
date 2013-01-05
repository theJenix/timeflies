#
# Required variables to run the app.  These are secret, and should not be
# specified in any public way.  These are defined as environment variables to
# allow for easy configuration with Heroku and other similar services.
#

ENV['ontime_username']      = ''
ENV['ontime_password']      = ''
ENV['ontime_client_id']     = ''
ENV['ontime_client_secret'] = ''

# The Rails secret token.  Generate using something like this:
# in IRB:
#   require "rails"
#   "#{ActiveSupport::SecureRandom.hex(64)}"
#
# and paste the response here.
ENV['secret_token']         = ''
