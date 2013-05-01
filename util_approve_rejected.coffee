mturk_lib = require './geoff_mturk'
async = require 'async'

ensure_not_paged = (context) ->
  if context.numResults!=context.totalNumResults
    throw 'ERROR: This tool was designed for a single page of results.'

Array::flatten = flatten = ->
  flat = []
  i = 0
  l = @length

  while i < l
    type = Object::toString.call(this[i]).split(" ").pop().split("]").shift().toLowerCase()
    flat = flat.concat((if /^(array|collection|arguments|object)$/.test(type) then flatten.call(this[i]) else this[i]))  if type
    i++
  flat

if require.main == module
  mturk = mturk_lib.get_mturk process.env.AWS_KEY, process.env.AWS_SECRET
  options =
    pageSize: 100
  mturk.HIT.getReviewable options, (error, numResults, totalNumResults, pageNumber, hits) ->
    ensure_not_paged this
    functions = []
    for hit in hits
      functions.push (result_callback) ->
        mturk.HIT.getAssignments hit.id, {}, (err, numResults, totalNumResults, pageNumber, assignments) ->
          ensure_not_paged this
          result_callback null, assignments
    
    async.parallel functions, (err, results) ->
      #console.log results.length
      results.flatten() # flatten
      #console.log results.length
      results = (a for a in results when a.assignmentStatus=='Rejected') # filter to only rejected
      #console.log results.length

      functions = []
      for a in results
        functions.push (result_callback) ->
          mturk.Assignment.approveRejected a.id, "Sorry I rejected this. It's APPROVED now. -Geoff", (error) ->
            if error
              console.log "ERROR approving rejected assignment #{a.id}: #{error}"
            else
              console.log "Successfully approved rejected assignment #{a.id}"
            result_callback null, null

      async.parallel functions, (err, results) ->
        console.log "Approved #{results.length} rejected HITs"
        process.exit()
