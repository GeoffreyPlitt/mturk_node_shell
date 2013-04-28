# Allow exporting via "root".
root = exports ? this

io = window.io.connect()

HELP = [
  'help'
  '    Show this help info.'
  'creds <KEY> <SECRET>'
  '    Set AWS creds. Stored in browser cache.'
  'clear_creds'
  '    Remove stored AWS creds'
  'go'
  '    Launch a HIT with default options.'
]

term = $('#term').terminal (line, term) ->
  parts = line.split ' '
  command = parts[0]
  args = (x for x in parts[1..] when x.length>0)
  switch command
    when 'go'
      creds = JSON.parse localStorage.getItem 'AWS_CREDS'
      io.emit 'launch_hit',
        creds: creds
    when 'help'
      (term.echo x for x in HELP)
    when 'clear_creds'
      localStorage.setItem 'AWS_CREDS', null
      term.echo 'AWS creds cleared.'
    when 'creds'
      error_text = 'Expected 2 parameters: <KEY> <SECRET>'
      if args.length != 2
        term.error error_text
      else
        key = args[0]
        secret = args[1]
        if key.length==0 or secret.length==0
          term.error error_text
        else
          localStorage.setItem 'AWS_CREDS', JSON.stringify [key, secret]
          term.echo 'AWS creds stored in browser cache.'
    else
      term.error 'Unknown command.'

  ret = this.prompt + command
  ret # return
,
  greetings: 'Welcome to MTurk Launcher. Type "help" for a list of commands.'
  rows: 20

term.resize 1000, 500
io.on 'log_output', (args) ->
  fixed = (args.data[x] for x of args.data).join ' '
  term.echo fixed