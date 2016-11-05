_history = []
_historySize = 300
_updateClosure = null
_cm = null
@_min = 0
@_max = 0
@log = (x)-> console.log x; return x

TAU = Math.PI * 2
# @x = 0

examples =
  sin: "frequency = 1 # Cycles per second\nMath.sin(time * frequency * TAU)"
  saw: "time % 1\n# The '1' isn't cycles-per-second — what is it?\n# When you change the mod, what happens to the max? Why?\n# What can you do to adjust the mod while keeping the output range between 0 and 1?"
  square: "Math.round(time % 1)\n# The '1' isn't cycles-per-second OR seconds-per-cycle — what is it?\n# When you change the mod, what happens to the rhythm?\n# What can you do to make a more uniform rhythm?"
  triangle: "Math.abs((time % 1 * 2) - 1)\n# This one is more complex. There's a simpler version with half the frequency:\n# Math.abs((time % 2) - 1)"
  silly: "c = Math.cos(time)\np = Math.pow(c, 3)\nMath.sin(p * TAU)\n# Playing with simple trig and pow can produce some fun results\n# What happens if you make the '3' a negative, or a decimal?\n# Watch the 'value' in the chart below"
  chaotic: "# Emergent complexity, much?\nc = Math.cos(time)\np = Math.pow(c, Math.round(2 * time % 3))\nMath.sin(p * TAU)"
  state: "# To put a variable on the window, use the @ sign\n# You should initialize your variables with ?= to avoid null/NaN issues\n@x ?= 0\nif (@x < 0.01)\n\t@x = 1\nelse\n\t@x *= 0.9\n@x"
  random: "Math.random() # Yes, you can access standard functions"
  dT: "dT # Try this in different browsers"
  log: "log(dT) # This is a special pass-through logging function — check your browser inspector!"


scale = (input, inputMin, inputMax, outputMin, outputMax)->
  if inputMax is inputMin
    outputMin
  else
    input -= inputMin
    input /= inputMax - inputMin
    input *= outputMax - outputMin
    input += outputMin
    input

compileSource = (editor)->
  source = editor.getValue()
  @localStorage["source"] = source
  console.clear()
  results = $('#repl_results')
  @compiledJS = ''
  try
    @compiledJS = CoffeeScript.compile source, bare: on
    results.text("")
  catch {location, message}
    if location?
      message = "Error on line #{location.first_line + 1}: #{message}"
    results.text(message).addClass 'error'


ready ()->
  canvas = document.querySelector "canvas"
  context = canvas.getContext "2d"
  
  # Configure CM
  CodeMirror.defaults.lineNumbers = true
  CodeMirror.defaults.tabSize = 2
  CodeMirror.defaults.historyEventDelay = 200
  CodeMirror.defaults.viewportMargin = Infinity
  CodeMirror.defaults.extraKeys =
    Tab: false
    "Shift-Tab": false
    "Cmd-Enter": ()->
      render(true)
  _cm = CodeMirror.fromTextArea $("textarea")[0], mode: 'coffeescript'
  _cm.on "changes", (editor, change)->
    compileSource(editor)
  
  $("button[wtf-type]").click (e)->
    _history = []
    _cm.setValue(examples[$(e.target).attr("wtf-type")])
    compileSource(_cm)
  
  if @localStorage["source"]?
    _cm.setValue(@localStorage["source"])
  else
    _cm.setValue(examples.sin)
  compileSource(_cm)
  
  _updateClosure = (t)-> update(canvas, t)
  firstTick = (t)->
    @time = t/1000
    requestAnimationFrame _updateClosure
  requestAnimationFrame firstTick




update = (canvas, t)->
  
  @dT = t/1000 - @time
  @time = t/1000
  
  try
    @value = eval @compiledJS
    if @value?
      _history.unshift @value
      _history.pop() if _history.length > _historySize
    
      render(canvas)
      
      for c in $("table tr [wtf-chart]")
        e = $(c)
        n = e.attr("wtf-chart")
        v = @[n]
        v = @["_#{n}"] unless v?
        e.text Math.round(v * 1000)/1000
  
  requestAnimationFrame _updateClosure




render = (canvas)->
  return unless _history.length > 0
  
  context = canvas.getContext "2d"
  
  # Just do everything at 2x so that we're good for most retina displays (hard to detect)
  width = canvas.width = parseInt(canvas.offsetWidth)
  height = canvas.height = parseInt(canvas.offsetHeight)
  
  cx = width/2
  cy = height/2
  
  @_min = Infinity
  @_max = -Infinity
  for v, i in _history
    @_max = v if v > @_max
    @_min = v if v < @_min

  
  context.beginPath()
  context.strokeStyle = "#CCC"
  y = scale(0, @_min, @_max, height, 0)
  context.moveTo(0, y);
  context.lineTo(width, y);
  context.stroke()

  context.beginPath()
  context.lineWidth = 2
  context.strokeStyle = "black"
  for v, i in _history
    x = i/(_historySize-1) * width
    y = scale(v, @_min, @_max, height, 0)
    if i == 0
      context.arc(x, y, 6, 0, TAU)
      context.fill()
      context.moveTo(x, y);
    else
      context.lineTo(x, y);
  context.stroke()
