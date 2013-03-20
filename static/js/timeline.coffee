window.Timeline = class Timeline
  constructor: (scope, el, socket) ->
    @scope = scope
    @t = 1297110663
    @v = 70

    w = @w = el.width()
    h = @h = el.height()
    @data = d3.range(@w / 20).map(-> time: 0, value: 0, message: {})
    @length = @data.length

    x = @x = d3.scale.linear().
      domain([0, 1]).
      rangeRound([0, 20])

    y = @y = d3.scale.linear().
      domain([0, 2000]).
      rangeRound([0, h])

    @chart = d3.select(el[0]).append('svg').
      attr('class', 'chart').
      attr('width', w).
      attr('height', h)

    @chart.selectAll('rect').
      data(@data).
      enter().append('rect').
      attr('x', (d, i) -> x(i) - .5).
      attr('y', (d) -> h - y(d.value) - .5).
      attr('width', 20).
      attr('height', (d) -> y(d.value))

    socket.on 'logMessage', (message) =>
      @data.shift()
      item = @next()
      item.time = Date.parse(message.requestedOn)
      item.value = message.duration
      item.message = message
      @data.push item
      @redraw()

  next: =>
    @v = @v + 10 * (Math.random() - .5)
    @v = ~~Math.max(10, Math.min(90, @v))
    @t += 1
    time: @t, value: @v

  redraw: ->
    rect = @chart.selectAll('rect').data(@data, (d) -> d.time)
    { x, y, w, h } = @

    rect.enter().insert('rect', 'line').
      attr('x', (d, i) -> x(i) - .5).
      attr('y', (d) -> h - y(d.value) - .5).
      attr('width', 20).
      attr('height', (d) -> y(d.value)).
      attr('class', (d) ->
        status = d.message.status || 0
        duration = d.value
        return 'server-error'  if status >= 500
        return 'client-error'  if status >= 400
        return 'long-running'  if duration > 1000
        return 'redirection'   if status >= 300
        return 'informational' if 100 <= status < 200
        return 'success'
      ).
      on('mouseover', (d) -> d.message.hover = true).
      on('mouseout', (d) -> d.message.hover = false).
      on('click', (d) =>
        @scope.setFocus d.message
      ).
      transition().
      duration((d) -> d.value).
      attr('x', (d, i) -> x(i) - .5)

    rect.transition().
      duration(100).
      attr('x', (d, i) -> x(i) - .5)

    rect.exit().transition().
      duration(100).
      attr('x', (d, i) -> x(i - 1) - .5).
      remove()