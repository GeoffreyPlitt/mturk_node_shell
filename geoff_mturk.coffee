# Allow exporting via "root".
root = exports ? this

mturk_lib = require 'mturk'
jsontoxml = require 'jsontoxml'

ONE_DAY_IN_SECONDS = 3600*24

# TODO: convert question to Jade

#--------- QUESTION
###
question_json= [{
  name: 'QuestionForm'
  attrs:
    xmlns:"http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd"
  children: [
    Overview: [
        Title: "Game 01523, \"X\" to play"
      ,
        Text: "You are helping to decide the next move in a game of Tic-Tac-Toe.  The board looks like this:"
      ,
        Binary:
          MimeType:
            Type: "image"
            SubType: "gif"

          DataURL: "http://tictactoe.amazon.com/game/01523/board.gif"
          AltText: "The game board, with \"X\" to move."
      ,
        Text: "Player \"X\" has the next move."
      ,
      ]
  ,
    Question:
      QuestionIdentifier: "nextmove"
      DisplayName: "The Next Move"
      IsRequired: "true"
      QuestionContent:
        Text: "What are the coordinates of the best move for player \"X\" in this game?"

      AnswerSpecification:
        FreeTextAnswer:
          Constraints: [
            name: 'Length'
            attrs: 
              "minLength": "2"
              "maxLength": "2"
          ]

          DefaultText: "C1"
  ,
    Question:
      QuestionIdentifier: "likelytowin"
      DisplayName: "The Next Move"
      IsRequired: "true"
      QuestionContent:
        Text: "How likely is it that player \"X\" will win this game?"

      AnswerSpecification:
        SelectionAnswer:
          StyleSuggestion: "radiobutton"
          Selections: [
            Selection:
              SelectionIdentifier: "notlikely"
              Text: "Not likely"
          ,
            Selection:
              SelectionIdentifier: "unsure"
              Text: "It could go either way"
          ,
            Selection:
              SelectionIdentifier: "likely"
              Text: "Likely"
          ]
  ]
}]
###
question_json= [{
  name: 'QuestionForm'
  attrs:
    xmlns:"http://mechanicalturk.amazonaws.com/AWSMechanicalTurkDataSchemas/2005-10-01/QuestionForm.xsd"
  children: [
    Overview: [
        Title: "Label An Image"
      ,
        Text: "Here is the image:"
      ,
        Binary:
          MimeType:
            Type: "image"
            SubType: "jpeg"
          DataURL: "http://turbo.fortytwotimes.com/wp-content/uploads/2012/06/Baby-With-Puppy-and-Ashtma.jpg"
          AltText: "[image]"
      ]
  ,
    Question:
      QuestionIdentifier: "labels"
      DisplayName: ""
      IsRequired: "true"
      QuestionContent:
        Text: "Please type a few keywords to describe this image"

      AnswerSpecification:
        FreeTextAnswer:
          Constraints: [
            name: 'Length'
            attrs: 
              "minLength": "3"
              "maxLength": "100"
          ]

          DefaultText: ""
  ,
    Question:
      QuestionIdentifier: "gender"
      DisplayName: ""
      IsRequired: "true"
      QuestionContent:
        Text: "What is your gender?"

      AnswerSpecification:
        FreeTextAnswer:
          Constraints: [
            name: 'Length'
            attrs: 
              "minLength": "3"
              "maxLength": "100"
          ]

          DefaultText: ""
  ]
}]

#my_log jsontoxml question_json
#process.exit()

#--------- CODE

_fix_answer = (answer) ->
  #my_log 'GP1', JSON.stringify(answer)
  name = answer.QuestionIdentifier
  delete answer.QuestionIdentifier
  prop = (x for x of answer)[0]
  ret =
    key: name
    val: answer[prop]
  #my_log 'GP2', ret
  ret

fix_answers = (answer_or_answers) ->
  if not Array.isArray answer_or_answers
    fix_answers [answer_or_answers] # always reroute as array
  else
    (_fix_answer x for x in answer_or_answers)

get_mturk = (key, secret) ->
  if not key or not secret
    throw new Error 'AWS creds not configured.'

  ret = mturk_lib
    # url: "https://mechanicalturk.sandbox.amazonaws.com"
    url: "https://mechanicalturk.amazonaws.com/"
    receptor:
      port: 8080
      host: undefined

    poller:
      frequency_ms: 3000  # 10000

    accessKeyId: key
    secretAccessKey: secret
  ret # return

console_logger = ->
  console.log arguments...

describe_seconds = (s) ->
  if s<60.0
    "#{s} secs"
  else
    "#{(s/60.0).toFixed(2)} mins"

root.go = (aws_key, aws_secret, my_log) ->
  reward =
    Amount: '0.05'
    CurrencyCode: 'USD'
  duration_per_hit = '60' # 1 minute to complete each hit
  hittype_options =
    keywords: 'categorization, images'
    autoApprovalDelayInSeconds: ONE_DAY_IN_SECONDS * 1
  hit_options=
    maxAssignments: 1
  lifeTimeInSeconds = 60 * 10 # 10 mins

  INFORM_EVERY = 30 # 30 secs

  mturk = get_mturk aws_key, aws_secret

  desc = question_json[0].children[0].Overview[0].Title
  my_log "Asking people to \"#{desc}\", with at most #{hit_options.maxAssignments} results for $#{reward.Amount} each, expiring in #{describe_seconds lifeTimeInSeconds}..."
  mturk.HITType.create desc, desc, reward, duration_per_hit, hittype_options, (error_list, resulting_hittype) ->
    if error_list?
      my_log 'ERRORS: ', error_list
    #my_log 'Creating Hit...'
    mturk.HIT.create resulting_hittype.id, (jsontoxml question_json), lifeTimeInSeconds, hit_options, (error_list, resulting_hit) ->
      if error_list?
        my_log 'ERRORS: ', error_list
      # my_log "HIT #{resulting_hit.id} created. Listening for results..."
      assignments_seen = []
      j = 0
      setInterval ->
        mturk.HIT.getAssignments resulting_hit.id, {}, (err, numResults, totalNumResults, pageNumber, assignments) ->
          # my_log 'Assignments info: ', arguments
          assignments.forEach (assignment) ->
            #my_log assignment
            if (assignment.hitId == resulting_hit.id) and ((assignments_seen.indexOf assignment.id) == -1)
              assignments_seen.push assignment.id
              j+=1
              fixed_answers = fix_answers assignment.answer.QuestionFormAnswers.Answer
              result_text = ("#{x.key}=#{JSON.stringify x.val}" for x in fixed_answers).join ', '
              my_log "Result ##{j}: #{result_text}"
      , 10*1000

      i = INFORM_EVERY
      intervalID = setInterval ->
        if lifeTimeInSeconds-i <=0
          clearInterval intervalID
          my_log "(finished - HIT expired)"
        else
          my_log "(#{describe_seconds lifeTimeInSeconds-i} left)"
          i += INFORM_EVERY
      , INFORM_EVERY*1000

if require.main == module
  key = process.env.AWS_KEY
  secret = process.env.AWS_SECRET
  go key, secret, console_logger