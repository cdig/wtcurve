window.addEventListener "DOMContentLoaded", ()->
  
  field = document.querySelector "[field]"
  canvas = document.querySelector "canvas"
  context = canvas.getContext "2d"
  width = canvas.width = parseInt canvas.offsetWidth
  height = canvas.height = width
  range = height * .7
  inset = (height-range)/2
  TAU = Math.PI*2
  nodeRadius = 4
  nodePad = 10
  nodes = null
  dragNode = null
  mouse = null
  pointsDirty = true
  focusing = false
  
  init = ()->
    nodes = []
    nodes.push x:0, y:0
    nodes.push x:1, y:1
  
  save = ()->
    localStorage.setItem "wtcurve", JSON.stringify nodes
  
  posToScreen = ({x:x, y:y})->
    x: width * x
    y: height - inset - y * range

  screenToPos = ({x:x, y:y})->
    x: Math.min 1, Math.max 0, x / width
    y: Math.min 1.2, Math.max -0.2, (height - inset - y) / range

  mouseToScreen = (e)->
    bounds = canvas.getBoundingClientRect()
    x: e.clientX - bounds.left
    y: e.clientY - bounds.top

  mouseToPos = (e)->
    screenToPos mouseToScreen e

  getNodeIndex = (node)->
    return i for n, i in nodes when n is node

  getNodeAtScreenPoint = (p)->
    for node, i in nodes
      return node if dist(posToScreen(node), p) <= nodeRadius + nodePad
    return null

  dist = (a, b)->
    dx = a.x-b.x
    dy = a.y-b.y
    Math.sqrt dx*dx + dy*dy
  
  evalCurve = (t)->
    points = nodes
    while points.length > 1
      nextPoints = []
      for a, i in points when i < points.length-1
        b = points[i+1]
        dx = b.x-a.x
        dy = b.y-a.y
        nextPoints.push p =
          x: a.x + dx*t
          y: a.y + dy*t
      points = nextPoints
    return points[0]
  
  evalCurveHistory = (t)->
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
  
  approx = (goal)->
    a = 0
    b = 1
    attempts = 0
    v = null
    while attempts < 20
      mid = (a + b)/2
      v = evalCurve mid
      if Math.abs(v.x - goal) < 0.0001 # Tends to finish in around 10 attempts
        return v.y
      else if v.x > goal
        b = mid
      else
        a = mid
      attempts++
    return v.y

  readField = ()->
    try
      return init() if field.innerText.length < 2
      arr = JSON.parse field.innerText
      return init() if arr.length < 2
      nodes = ({ x: p[0], y: p[1] } for p in arr)
      nodes[0].x = 0
      nodes[nodes.length-1].x = 1
      pointsDirty = true
      render()
      
  
  renderNode = (n)->
    "[" + Math.round(n.x*100)/100 + "," + Math.round(n.y*100)/100 + "]"
  
  render = ()->
    if pointsDirty
      pointsDirty = false
      save()
      if not focusing
        field.innerHTML = "[" + nodes.map(renderNode).join(", ") + "]"
    
    context.clearRect 0,0,width,height
    
    # Draw BG
    context.beginPath()
    context.fillStyle = "#FFF"
    context.rect 0, inset, width, range
    context.fill()
    
    if mouse?
      mp = mouseToPos mouse
      ms = mouseToScreen mouse
      history = evalCurveHistory mp.x

      # Red approx dot
      x = ms.x
      y = posToScreen(x:0, y: approx mp.x).y
      context.beginPath()
      context.fillStyle = "#F00"
      context.arc x, y, 5, 0, TAU
      context.fill()

    else
      history = evalCurveHistory 0


    # Grey histories & pos dot
    for points, h in history
      context.beginPath()
      for point, i in points when points.length > 1
        p = posToScreen x:point.x, y: point.y
        if i is 0
          context.moveTo p.x, p.y
        else
          context.lineTo p.x, p.y
      a = 1 - .98 * Math.pow h/(history.length-1), .05
      context.strokeStyle = "rgba(0,0,0,#{a})"
      context.stroke()
    
    # Red curve
    context.beginPath()
    context.strokeStyle = "#F00"
    context.lineWidth = 3
    inc = 0.01
    t = 0
    while t <= 1
      point = evalCurve(t)
      p = posToScreen x:point.x, y:point.y
      if t is 0
        context.moveTo p.x, p.y
      else
        context.lineTo p.x, p.y
      t += inc
    context.stroke()
    context.lineWidth = 1
    
    # Nodes
    hoverNode = getNodeAtScreenPoint mouseToScreen mouse if mouse?
    for node in nodes
      context.beginPath()
      p = posToScreen node
      context.arc p.x, p.y, nodeRadius, 0, TAU
      context.fillStyle = if node is dragNode then "#FB0" else if node is hoverNode then "#F70" else "#444"
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
    e.preventDefault()
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
  
  field.addEventListener "keyup", readField
  field.addEventListener "focus", ()-> focusing = true
  field.addEventListener "blur", ()-> readField focusing = false
  
  (nodes = JSON.parse localStorage.getItem "wtcurve") or init()
  render()
