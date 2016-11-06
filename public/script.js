(function() {
  var TAU, bounds, canvas, context, dist, dragNode, evalCurve, field, getNodeAtScreenPoint, getNodeIndex, height, inset, mouse, mouseToPos, mouseToScreen, nodeRadius, nodes, pointsDirty, posToScreen, range, render, renderNode, screenToPos, width;

  field = document.querySelector("[field]");

  canvas = document.querySelector("canvas");

  context = canvas.getContext("2d");

  width = canvas.width = parseInt(canvas.offsetWidth);

  height = canvas.height = width;

  bounds = canvas.getBoundingClientRect();

  range = height * .7;

  inset = (height - range) / 2;

  TAU = Math.PI * 2;

  nodeRadius = 15;

  nodes = [];

  dragNode = null;

  mouse = null;

  pointsDirty = true;

  posToScreen = function(arg) {
    var x, y;
    x = arg.x, y = arg.y;
    return {
      x: width * x,
      y: height - inset - y * range
    };
  };

  screenToPos = function(arg) {
    var x, y;
    x = arg.x, y = arg.y;
    return {
      x: Math.min(1, Math.max(0, x / width)),
      y: Math.min(1.2, Math.max(-0.2, (height - inset - y) / range))
    };
  };

  mouseToScreen = function(e) {
    return {
      x: e.clientX - bounds.left,
      y: e.clientY - bounds.top
    };
  };

  mouseToPos = function(e) {
    return screenToPos(mouseToScreen(e));
  };

  getNodeIndex = function(node) {
    var i, j, len, n;
    for (i = j = 0, len = nodes.length; j < len; i = ++j) {
      n = nodes[i];
      if (n === node) {
        return i;
      }
    }
  };

  getNodeAtScreenPoint = function(p) {
    var i, j, len, node;
    for (i = j = 0, len = nodes.length; j < len; i = ++j) {
      node = nodes[i];
      if (dist(posToScreen(node), p) <= nodeRadius) {
        return node;
      }
    }
    return null;
  };

  dist = function(a, b) {
    var dx, dy;
    dx = a.x - b.x;
    dy = a.y - b.y;
    return Math.sqrt(dx * dx + dy * dy);
  };

  evalCurve = function(t) {
    var a, b, dx, dy, history, i, j, len, nextPoints, p, points;
    history = [nodes];
    points = nodes;
    while (points.length > 1) {
      history.push(nextPoints = []);
      for (i = j = 0, len = points.length; j < len; i = ++j) {
        a = points[i];
        if (!(i < points.length - 1)) {
          continue;
        }
        b = points[i + 1];
        dx = b.x - a.x;
        dy = b.y - a.y;
        nextPoints.push(p = {
          x: a.x + dx * t,
          y: a.y + dy * t
        });
      }
      points = nextPoints;
    }
    return history;
  };

  renderNode = function(n) {
    return "[" + Math.round(n.x * 100) / 100 + "," + Math.round(n.y * 100) / 100 + "]";
  };

  render = function() {
    var g, h, history, hoverNode, i, inc, j, k, l, len, len1, len2, m, node, p, point, points, results, t;
    if (pointsDirty) {
      field.innerHTML = "[" + nodes.map(renderNode).join(", ") + "]";
      pointsDirty = false;
    }
    context.clearRect(0, 0, width, height);
    context.beginPath();
    context.fillStyle = "#FFF";
    context.rect(0, inset, width, range);
    context.fill();
    if (mouse != null) {
      m = mouseToPos(mouse);
      history = evalCurve(m.x);
      for (h = j = 0, len = history.length; j < len; h = ++j) {
        points = history[h];
        context.beginPath();
        g = 220 - 140 * h / history.length;
        context.strokeStyle = "rgb(" + g + "," + g + "," + g + ")";
        for (i = k = 0, len1 = points.length; k < len1; i = ++k) {
          point = points[i];
          p = posToScreen({
            x: point.x,
            y: point.y
          });
          if (points.length === 1) {
            context.arc(p.x, p.y, 3, 0, TAU);
            context.fillStyle = "#008";
            context.fill();
          } else if (i === 0) {
            context.moveTo(p.x, p.y);
          } else {
            context.lineTo(p.x, p.y);
          }
        }
        context.stroke();
      }
    }
    context.beginPath();
    context.strokeStyle = "#F00";
    context.lineWidth = 3;
    inc = 0.01;
    t = 0;
    while (t <= 1) {
      history = evalCurve(t);
      point = history[history.length - 1][0];
      p = posToScreen({
        x: point.x,
        y: point.y
      });
      if (t === 0) {
        context.moveTo(p.x, p.y);
      } else {
        context.lineTo(p.x, p.y);
      }
      t += inc;
    }
    context.stroke();
    context.lineWidth = 1;
    if (mouse != null) {
      hoverNode = getNodeAtScreenPoint(mouseToScreen(mouse));
    }
    results = [];
    for (l = 0, len2 = nodes.length; l < len2; l++) {
      node = nodes[l];
      context.beginPath();
      p = posToScreen(node);
      context.arc(p.x, p.y, nodeRadius, 0, TAU);
      context.fillStyle = node === dragNode ? "#F80" : node === hoverNode ? "#FD7" : "#AAA";
      results.push(context.fill());
    }
    return results;
  };

  canvas.addEventListener("mousedown", function(e) {
    dragNode = getNodeAtScreenPoint(mouseToScreen(e));
    return render();
  });

  window.addEventListener("mousemove", function(e) {
    var i, p;
    mouse = e;
    if (dragNode) {
      p = mouseToPos(e);
      i = getNodeIndex(dragNode);
      if (i === 0) {
        p.x = 0;
      }
      if (i === nodes.length - 1) {
        p.x = 1;
      }
      if (Math.abs(p.y) < 0.015) {
        p.y = 0;
      }
      if (Math.abs(p.y - 1) < 0.015) {
        p.y = 1;
      }
      dragNode.x = p.x;
      dragNode.y = p.y;
      pointsDirty = true;
    }
    return render();
  });

  window.addEventListener("mouseup", function(e) {
    dragNode = null;
    return render();
  });

  canvas.addEventListener("dblclick", function(e) {
    var i, j, len, n, node, p;
    if (node = getNodeAtScreenPoint(mouseToScreen(e))) {
      i = getNodeIndex(node);
      if (i !== 0 && i !== nodes.length - 1) {
        nodes.splice(i, 1);
      }
    } else {
      p = mouseToPos(e);
      for (i = j = 0, len = nodes.length; j < len; i = ++j) {
        n = nodes[i];
        if (n.x >= p.x) {
          nodes.splice(i, 0, p);
          break;
        }
      }
    }
    pointsDirty = true;
    return render();
  });

  nodes.push({
    x: 0,
    y: 0
  });

  nodes.push({
    x: 1,
    y: 1
  });

  render();

}).call(this);
