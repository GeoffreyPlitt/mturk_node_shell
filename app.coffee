#--------------------------------- Requires --------------------------------
process.stdout.write 'Loading modules...'
http =             require 'http'
Logger =           require 'basic-logger'
express =          require 'express.io'
stylus =           require 'stylus'
nib =              require 'nib'
fs =               require 'fs'
coffeescript =     require 'coffee-script'
connect_assets =   require 'connect-assets'
jade_assets =      require 'connect-assets-jade'
google_auth =      require 'connect-googleapps'
geoff_mturk =       require './geoff_mturk'
console.log 'done.'

#--------------------------------- Constants --------------------------------
AUTH_WHITELIST = [
  'geoff@gweb.org'
]

PROJ_TO_HOSTNAME =
  margindev: 'margin-dev.makerstudios.com'

APP_PORT = 8080

#----------------------------- General Helper Funcs ------------------------

log_error_or_continue = (prefix, continuation) ->
  (err, the_rest) ->
    if err
      log.error "ERROR(#{prefix}): "
    else
      continuation the_rest

#--------------------------------- Logging setup --------------------------------
log = new Logger
  showMillis: true
  showTimestamp: true

#--------------------------------- Passport setup --------------------------------

#--------------------------------- Express setup --------------------------------
app = express()
app.http().io()
app.listen APP_PORT

app.configure ->
  #google_auth('localhost')

  app.use express.cookieParser()
  app.use express.bodyParser()
  app.use express.methodOverride()
  app.use express.session
    secret: 'fgjfgjfgjsfgj45673uhwrth'

  app.set 'view engine', 'jade'
  app.set 'views', __dirname + '/assets'

  app.use connect_assets
    jsCompilers:
      jade: jade_assets()

  app.use express.favicon()
  app.use app.router
  app.use express.logger()

  app.get "/", (req, res) ->
    res.render 'index'
    #  user_email: (x.value for x in req.user.emails)[0]

  app.io.route 'launch_hit', (req) ->
    geoff_mturk.go ->
      console.log '[geoff_mturk] ', arguments...
      req.io.emit 'log_output',
        data: arguments

  console.log "Server started, listening on port #{APP_PORT}"
  console.log ''

