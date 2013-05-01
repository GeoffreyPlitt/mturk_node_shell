mturk_lib = require './geoff_mturk'
async = require 'async'

ensure_not_paged = (context) ->
  if context.numResults!=context.totalNumResults
    throw 'ERROR: This tool was designed for a single page of results.'

flatten = (array) ->
  result = []
  self = arguments.callee
  array.forEach (item) ->
    Array::push.apply result, (if Array.isArray(item) then self(item) else [item])
  result

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
      results = flatten results # flatten
      #console.log results.length
      results = (a.id for a in results when a.assignmentStatus=='Rejected') # filter to only rejected
      #console.log results.length

      functions = []
      for a_id in results
        functions.push (result_callback) ->
          mturk.Assignment.approveRejected a_id, "Sorry I rejected this. It's APPROVED now. -Geoff", (error) ->
            if error
              console.log "ERROR approving rejected assignment #{a_id}: #{error}"
            else
              console.log "Successfully approved rejected assignment #{a_id}"
            result_callback null, null

      async.parallel functions, (err, results) ->
        console.log "Approved #{results.length} rejected HITs"
        process.exit()
