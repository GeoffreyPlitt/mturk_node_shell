# Allow exporting via "root".
root = exports ? this

io = window.io.connect()

term = $('#term').terminal (command, term) ->
  switch command
    when 'go'
      io.emit 'launch_hit'
    when 'help'
      term.echo 'help: shows this message'
      term.echo 'go: launches a hit'
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