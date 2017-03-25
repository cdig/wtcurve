(function() {
  window.addEventListener("DOMContentLoaded", function() {
    var TAU, approx, canvas, context, dist, dragNode, evalCurve, evalCurveHistory, field, focusing, getNodeAtScreenPoint, getNodeIndex, height, init, inset, mouse, mouseToPos, mouseToScreen, nodeRadius, nodes, pointsDirty, posToScreen, range, readField, render, renderNode, save, screenToPos, width;
    field = document.querySelector("[field]");
    canvas = document.querySelector("canvas");
    context = canvas.getContext("2d");
    width = canvas.width = parseInt(canvas.offsetWidth);
    height = canvas.height = width;
    range = height * .7;
    inset = (height - range) / 2;
    TAU = Math.PI * 2;
    nodeRadius = 15;
    nodes = null;
    dragNode = null;
    mouse = null;
    pointsDirty = true;
    focusing = false;
    init = function() {
      nodes = [];
      nodes.push({
        x: 0,
        y: 0
      });
      nodes.push({
        x: 1,
        y: 1
      });
      return render();
    };
    save = function() {
      return localStorage.setItem("wtcurve", JSON.stringify(nodes));
    };
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
      var bounds;
      bounds = canvas.getBoundingClientRect();
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
      var a, b, dx, dy, i, j, len, nextPoints, p, points;
      points = nodes;
      while (points.length > 1) {
        nextPoints = [];
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
      return points[0];
    };
    evalCurveHistory = function(t) {
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
    approx = function(goal) {
      var a, attempts, b, mid, v;
      a = 0;
      b = 1;
      attempts = 0;
      v = null;
      while (attempts < 20) {
        mid = (a + b) / 2;
        v = evalCurve(mid);
        if (Math.abs(v.x - goal) < 0.0001) {
          return v.y;
        } else if (v.x > goal) {
          b = mid;
        } else {
          a = mid;
        }
        attempts++;
      }
      return v.y;
    };
    readField = function() {
      var arr, p;
      try {
        if (field.innerText.length < 2) {
          return init();
        }
        arr = JSON.parse(field.innerText);
        if (arr.length < 2) {
          return init();
        }
        nodes = (function() {
          var j, len, results;
          results = [];
          for (j = 0, len = arr.length; j < len; j++) {
            p = arr[j];
            results.push({
              x: p[0],
              y: p[1]
            });
          }
          return results;
        })();
        nodes[0].x = 0;
        nodes[nodes.length - 1].x = 1;
        pointsDirty = true;
        return render();
      } catch (error) {}
    };
    renderNode = function(n) {
      return "[" + Math.round(n.x * 100) / 100 + "," + Math.round(n.y * 100) / 100 + "]";
    };
    render = function() {
      var g, h, history, hoverNode, i, inc, j, k, l, len, len1, len2, mp, ms, node, p, point, points, results, t, x, y;
      if (pointsDirty) {
        pointsDirty = false;
        save();
        if (!focusing) {
          field.innerHTML = "[" + nodes.map(renderNode).join(", ") + "]";
        }
      }
      context.clearRect(0, 0, width, height);
      context.beginPath();
      context.fillStyle = "#FFF";
      context.rect(0, inset, width, range);
      context.fill();
      if (mouse != null) {
        mp = mouseToPos(mouse);
        ms = mouseToScreen(mouse);
        history = evalCurveHistory(mp.x);
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
              context.arc(p.x, p.y, 5, 0, TAU);
              context.strokeStyle = "#555";
              context.stroke();
            } else if (i === 0) {
              context.moveTo(p.x, p.y);
            } else {
              context.lineTo(p.x, p.y);
            }
          }
          context.stroke();
        }
        x = ms.x;
        y = posToScreen({
          x: 0,
          y: approx(mp.x)
        }).y;
        context.beginPath();
        context.fillStyle = "#080";
        context.arc(x, y, 5, 0, TAU);
        context.fill();
      }
      context.beginPath();
      context.strokeStyle = "#F00";
      context.lineWidth = 3;
      inc = 0.01;
      t = 0;
      while (t <= 1) {
        point = evalCurve(t);
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
      e.preventDefault();
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
    field.addEventListener("keyup", readField);
    field.addEventListener("focus", function() {
      return focusing = true;
    });
    field.addEventListener("blur", function() {
      return readField(focusing = false);
    });
    return (nodes = JSON.parse(localStorage.getItem("wtcurve"))) || init();
  });

}).call(this);
