app.directive 'timeline', (socket) ->
  directive =
    restrict: 'E'
    replace: true
    template: '<div id="timeline"></div>'
    link: (scope, element, attrs) -> scope.timeline = new Timeline(scope, element, socket)


app.directive 'eulogistScrollToEnd', ($timeout) ->
  (scope, element, attrs) ->
    userScroll = false
    autoScroll = true
    lastScrollEvent = Date.now()

    # monitor scroll events
    element.on 'scroll', ->
      currentScrollEvent = Date.now()
      if autoScroll && currentScrollEvent - lastScrollEvent < 50
        userScroll = true
        autoScroll = false
      else if userScroll && element[0].scrollTop / (element[0].scrollHeight - element[0].clientHeight) == 1
        autoScroll = true
        userScroll = false
      lastScrollEvent = currentScrollEvent

    # disable scroll if a message gets focus
    scope.$on 'messageFocus', ->
      userScroll = true
      autoScroll = false

    # autoscroller
    scrollToEnd = ->
      element.scrollTop(element[0].scrollHeight) if autoScroll
      $timeout scrollToEnd, 150
    scrollToEnd()

app.directive 'eulogistJumpToFocused', ($timeout) ->
  (scope, element, attrs) ->
    scope.$on 'messageFocus', ->
      $timeout ->
        focusedEntry = element.find('.entry.focus')
        focusedEntry[0].scrollIntoView() if focusedEntry.length == 1
      , 200
