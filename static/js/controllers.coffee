app.controller 'eulogist', ($scope, socket) ->
  $scope.messages = []
  $scope.focusedMessage = null

  $scope.setFocus = (message) ->
    $scope.focusedMessage.focus = false if $scope.focusedMessage
    $scope.focusedMessage = message
    message.focus = true
    $scope.$emit 'messageFocus', message

  socket.on 'logMessage', (message) ->
    messages = $scope.messages
    messages.shift() if messages.length >= $scope.timeline.length
    messages.push(message)

app.controller 'status', ($scope, socket) ->
  INFO = 'label-info'
  SUCCESS = 'label-success'
  ERROR = 'label-important'
  WARN = 'label-warning'

  updateStatus = (status, type) ->
    $scope.status = status
    $scope.statusType = type

    if status == 'connected' || status == 'reconnected'
      $scope.animation = 'fade-out'
    else
      $scope.animation = 'fade-in'

  socket.on 'connect',          -> updateStatus('connected', SUCCESS)
  socket.on 'connecting',       -> updateStatus('connecting', INFO)
  socket.on 'disconnect',       -> updateStatus('disconnected', WARN)
  socket.on 'connect_failed',   -> updateStatus('failed to connect', ERROR)
  socket.on 'error',            -> updateStatus('error', ERROR)
  socket.on 'reconnect_failed', -> updateStatus('failed to reconnect', ERROR)
  socket.on 'reconnect',        -> updateStatus('reconnected', SUCCESS)
  socket.on 'reconnecting',     -> updateStatus('reconnecting', INFO)
