app.filter 'statusText', ->
  (input) ->
    status = input.status
    duration = input.duration
    return 'server-error'  if status >= 500
    return 'client-error'  if status >= 400
    return 'long-running'  if duration > 1000
    return 'redirection'   if status >= 300
    return 'informational' if 100 <= status < 200
    return 'success'