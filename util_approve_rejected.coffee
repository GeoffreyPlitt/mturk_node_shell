mturk_lib = require './geoff_mturk'
async = require 'async'

ensure_not_paged = (context) ->
  if context.numResults!=context.totalNumResults
    throw 'ERROR: This tool was designed for a single page of results.'

if require.main == module
  mturk = mturk_lib.get_mturk process.env.AWS_KEY, process.env.AWS_SECRET
  options =
    pageSize: 100
  mturk.HIT.getReviewable options, (error, numResults, totalNumResults, pageNumber, hits) ->
    ensure_not_paged this
    for hit in hits
      mturk.HIT.getAssignments hit.id, {}, (err, numResults, totalNumResults, pageNumber, assignments) ->
        ensure_not_paged this
        rejected = (a for a in assignments when a.assignmentStatus=='Rejected')
        for a in rejected
          mturk.Assignment.approveRejected a.id, "Sorry I rejected this. It's APPROVED now. -Geoff", (error) ->
            if error
              console.log "ERROR approving rejected assignment #{a.id}: #{error}"
            else
              console.log "Successfully approved rejected assignment #{a.id}"