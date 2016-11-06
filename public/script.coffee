field = document.querySelector "[field]"
canvas = document.querySelector "canvas"
context = canvas.getContext "2d"
width = canvas.width = parseInt canvas.offsetWidth
height = canvas.height = width
bounds = canvas.getBoundingClientRect()
range = height * .7
inset = (height-range)/2
TAU = Math.PI*2
nodeRadius = 15
nodes = []
dragNode = null
mouse = null
pointsDirty = true

posToScreen = ({x:x, y:y})->
  x: width * x
  y: height - inset - y * range

screenToPos = ({x:x, y:y})->
  x: Math.min 1, Math.max 0, x / width
  y: Math.min 1.2, Math.max -0.2, (height - inset - y) / range

mouseToScreen = (e)->
  x: e.clientX - bounds.left
  y: e.clientY - bounds.top

mouseToPos = (e)->
  screenToPos mouseToScreen e

getNodeIndex = (node)->
  return i for n, i in nodes when n is node

getNodeAtScreenPoint = (p)->
  for node, i in nodes
    return node if dist(posToScreen(node), p) <= nodeRadius
  return null

dist = (a, b)->
  dx = a.x-b.x
  dy = a.y-b.y
  Math.sqrt dx*dx + dy*dy

evalCurve = (t)->
  history = [nodes]
  points = nodes
  while points.length > 1
    history.push nextPoints = []
    for a, i in points when i < points.length-1
      b = points[i+1]
      dx = b.x-a.x
      dy = b.y-a.y
      nextPoints.push p =
        x: a.x + dx*t
        y: a.y + dy*t
    points = nextPoints
  return history

renderNode = (n)->
  "[" + Math.round(n.x*100)/100 + "," + Math.round(n.y*100)/100 + "]"

render = ()->
  if pointsDirty
    field.innerHTML = "[" + nodes.map(renderNode).join(", ") + "]"
    pointsDirty = false
  
  # nodes.sort (a, b)-> a.x - b.x
  context.clearRect 0,0,width,height
  
  context.beginPath()
  context.fillStyle = "#FFF"
  context.rect 0, inset, width, range
  context.fill()

  if mouse?
    m = mouseToPos mouse
    history = evalCurve m.x
    for points, h in history
      context.beginPath()
      g = 220 - 140 * h/history.length
      context.strokeStyle = "rgb(#{g},#{g},#{g})"
      for point, i in points
        p = posToScreen x:point.x, y: point.y
        if points.length is 1
          context.arc p.x, p.y, 3, 0, TAU
          context.fillStyle = "#008"
          context.fill()
        else if i is 0
          context.moveTo p.x, p.y
        else
          context.lineTo p.x, p.y
      context.stroke()

  context.beginPath()
  context.strokeStyle = "#F00"
  context.lineWidth = 3
  inc = 0.01
  t = 0
  while t <= 1
    history = evalCurve t
    point = history[history.length-1][0]
    p = posToScreen x:point.x, y:point.y
    if t is 0
      context.moveTo p.x, p.y
    else
      context.lineTo p.x, p.y
    t += inc
  context.stroke()
  context.lineWidth = 1
  
  if mouse?
    hoverNode = getNodeAtScreenPoint mouseToScreen mouse
  
  for node in nodes
    context.beginPath()
    p = posToScreen node
    context.arc p.x, p.y, nodeRadius, 0, TAU
    context.fillStyle = if node is dragNode then "#F80" else if node is hoverNode then "#FD7" else "#AAA"
    context.fill()

        

canvas.addEventListener "mousedown", (e)->
  dragNode = getNodeAtScreenPoint mouseToScreen e
  render()

window.addEventListener "mousemove", (e)->
  mouse = e
  if dragNode
    p = mouseToPos e
    i = getNodeIndex dragNode
    p.x = 0 if i is 0
    p.x = 1 if i is nodes.length-1
    p.y = 0 if Math.abs(p.y) < 0.015
    p.y = 1 if Math.abs(p.y - 1) < 0.015
    dragNode.x = p.x
    dragNode.y = p.y
    pointsDirty = true
  render()

window.addEventListener "mouseup", (e)->
  dragNode = null
  render()

canvas.addEventListener "dblclick", (e)->
  if node = getNodeAtScreenPoint mouseToScreen e
    i = getNodeIndex node
    nodes.splice i, 1 if i isnt 0 and i isnt nodes.length-1
  else
    p = mouseToPos e
    for n, i in nodes
      if n.x >= p.x
        nodes.splice i, 0, p
        break
  pointsDirty = true
  render()
  
nodes.push x:0, y:0
nodes.push x:1, y:1
render()
