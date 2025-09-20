-- Overlay Visual Half-QWERTY (Left via Space) — US-International
-- Mostra/oculta via URL: hammerspoon://halfq?show=1 | show=0
-- + Trainer de Ritmo (hotkeys no final)

------------------------------------------------------------
-- DETECÇÃO DE RECURSOS / FALLBACK
------------------------------------------------------------
local HAS_CANVAS = (hs.canvas and type(hs.canvas.new) == "function")
local CANVAS_CLICKS_THROUGH = false
if HAS_CANVAS then
  local tmp = hs.canvas.new({x=0,y=0,w=1,h=1})
  local mt = getmetatable(tmp)
  CANVAS_CLICKS_THROUGH = mt and (type(mt.clicksThrough) == "function") or false
  tmp:delete()
end

------------------------------------------------------------
-- GEOMETRIA / ESTILO
------------------------------------------------------------
local PAD   = 16
local W, H  = 820, 420
local KEY_W = 52
local KEY_H = 44
local GAP_X = 10
local GAP_Y = 12
local FONT  = "Menlo"

local bgColor   = {alpha=0.90, red=0.07, green=0.07, blue=0.10}
local borderCol = {alpha=0.95, red=1.00, green=1.00, blue=1.00}
local textColor = {alpha=1.0,  red=1.00, green=1.00, blue=1.00}
local subColor  = {alpha=0.9,  red=0.80, green=0.80, blue=0.80}
local keyFill   = {alpha=0.20, red=0.90, green=0.90, blue=0.95}
local keyStroke = {alpha=0.8,  red=0.95, green=0.95, blue=0.95}

local function frameForCenter(width, height)
  local scr = hs.screen.mainScreen()
  local f = scr and scr:frame() or hs.geometry.rect(0,0,1440,900)
  return hs.geometry.rect(f.x + (f.w - width)/2, f.y + (f.h - height)/5, width, height)
end

------------------------------------------------------------
-- LAYOUT (pares em UM QUADRADO: topo=pressed, baixo=sent)
------------------------------------------------------------
local LAYOUT = {
  { {"`","="}, {"1","0"}, {"2","9"}, {"3","8"}, {"4","7"}, {"5","6"} },
  { {"Q","P"}, {"W","O"}, {"E","I"}, {"R","U"}, {"T","Y"} },
  { {"A",";"}, {"S","L"}, {"D","K"}, {"F","J"}, {"G","H"} },
  { {"Z","/"}, {"X","."}, {"C",","}, {"V","M"}, {"B","N"} },
  { {"-","["}, {"=" ,"]"}, {"Tab","\\"} }
}

------------------------------------------------------------
-- CANVAS (overlay estático com pares)
------------------------------------------------------------
local canvasOverlay = nil

local function canvasAddKeyPair(c, idx, x, y, topLabel, bottomLabel)
  c[idx] = {
    type="rectangle", fillColor=keyFill, strokeColor=keyStroke, strokeWidth=2,
    roundedRectRadii={xRadius=8,yRadius=8}, frame={x=x, y=y, w=KEY_W, h=KEY_H}
  }
  c[idx+1] = {
    type="text", text=topLabel, textSize=16, textColor=textColor,
    frame={x=x, y=y+2, w=KEY_W, h=KEY_H/2}, textAlignment="center"
  }
  c[idx+2] = {
    type="text", text=bottomLabel, textSize=16, textColor=subColor,
    frame={x=x, y=y+KEY_H/2-2, w=KEY_W, h=KEY_H/2}, textAlignment="center"
  }
  return idx+3
end

local function makeCanvas()
  if canvasOverlay then return end
  canvasOverlay = hs.canvas.new(frameForCenter(W,H))
  canvasOverlay:level(hs.canvas.windowLevels.screenSaver)
  if CANVAS_CLICKS_THROUGH then canvasOverlay:clicksThrough(true) end

  canvasOverlay[1] = {
    type="rectangle", fillColor=bgColor, strokeColor=borderCol, strokeWidth=2,
    roundedRectRadii={xRadius=18,yRadius=18}, frame={x=0,y=0,w=W,h=H}
  }
  canvasOverlay[2] = {
    type="text", text="Half-QWERTY (Left via Space) — US-International",
    textSize=18, textColor=textColor, frame={x=PAD, y=PAD, w=W-2*PAD, h=24}
  }
  canvasOverlay[3] = {
    type="text", text="Segure SPACE para ativar • Soltou, some",
    textSize=13, textColor=subColor, frame={x=PAD, y=PAD+22, w=W-2*PAD, h=20}
  }

  local startY = PAD + 58
  local idx = 4
  for row = 1, #LAYOUT do
    local y = startY + (row-1)*(KEY_H + GAP_Y)
    local x = PAD
    for col = 1, #LAYOUT[row] do
      local topLabel, bottomLabel = LAYOUT[row][col][1], LAYOUT[row][col][2]
      idx = canvasAddKeyPair(canvasOverlay, idx, x, y, topLabel, bottomLabel)
      x = x + KEY_W + GAP_X
    end
  end
end

local function canvasShow()
  if not canvasOverlay then makeCanvas() end
  canvasOverlay:frame(frameForCenter(W,H))
  canvasOverlay:show()
end
local function canvasHide() if canvasOverlay then canvasOverlay:hide() end end

------------------------------------------------------------
-- SINTETIZAÇÃO DE CLIQUE (F1 como button1)
------------------------------------------------------------
local syntheticMouseDown = false
local lastClickAt = 0
local lastClickPos = nil
local clickCount = 0
local currentClickState = 0
local CLICK_DIST_SQ = 36 -- 6px tolerância

local function computeClickState(pos)
  local now = hs.timer.secondsSinceEpoch()
  local interval = (hs.eventtap and hs.eventtap.doubleClickInterval and hs.eventtap.doubleClickInterval()) or 0.3
  local sameSpot = false
  if lastClickPos then
    local dx = pos.x - lastClickPos.x
    local dy = pos.y - lastClickPos.y
    sameSpot = (dx * dx + dy * dy) <= CLICK_DIST_SQ
  end
  if (now - lastClickAt) <= interval and sameSpot then
    clickCount = math.min(clickCount + 1, 3)
  else
    clickCount = 1
  end
  lastClickAt = now
  lastClickPos = { x = pos.x, y = pos.y }
  currentClickState = clickCount
  return clickCount
end

local function applyClickState(ev, state)
  if state and state > 0 and hs.eventtap and hs.eventtap.event.properties and hs.eventtap.event.properties.mouseEventClickState then
    ev:setProperty(hs.eventtap.event.properties.mouseEventClickState, state)
  end
end

local function ensureMouseDown()
  if syntheticMouseDown then return end
  local pos = hs.mouse.absolutePosition()
  local clickState = computeClickState(pos)
  local ev = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseDown, pos)
  applyClickState(ev, clickState)
  ev:post()
  syntheticMouseDown = true
end
local function ensureMouseUp()
  if not syntheticMouseDown then return end
  local pos = hs.mouse.absolutePosition()
  local ev = hs.eventtap.event.newMouseEvent(hs.eventtap.event.types.leftMouseUp, pos)
  applyClickState(ev, currentClickState)
  ev:post()
  syntheticMouseDown = false
  currentClickState = 0
end

------------------------------------------------------------
-- DRAWING (fallback)
------------------------------------------------------------
local drawingParts = nil
local function drawText(fr, str, size, color, align)
  local styled = hs.styledtext.new(str, {
    font = { name = FONT, size = size }, color = color or textColor,
    paragraphStyle = { alignment = align or "center" }
  })
  local t = hs.drawing.text(fr, styled)
  t:setLevel(hs.drawing.windowLevels.screenSaver)
  t:setClickThrough(true)
  return t
end
local function drawRoundedRect(rect, radius)
  local r = hs.drawing.rectangle(rect)
  r:setFill(true):setFillColor(keyFill)
  r:setStroke(true):setStrokeColor(keyStroke):setStrokeWidth(2)
  r:setRoundedRectRadii(radius, radius)
  r:setLevel(hs.drawing.windowLevels.screenSaver)
  r:setClickThrough(true)
  return r
end
local function makeDrawing()
  if drawingParts then return end
  drawingParts = {}
  local rect = frameForCenter(W,H)
  local bg = hs.drawing.rectangle(rect)
  bg:setFill(true):setFillColor(bgColor)
  bg:setStroke(true):setStrokeColor(borderCol):setStrokeWidth(2)
  bg:setRoundedRectRadii(18,18)
  bg:setLevel(hs.drawing.windowLevels.screenSaver)
  bg:setClickThrough(true)
  table.insert(drawingParts, bg)
  table.insert(drawingParts, drawText({x=rect.x+PAD,y=rect.y+PAD,w=W-2*PAD,h=24},
    "Half-QWERTY (Left via Space) — US-International", 18, textColor, "left"))
  table.insert(drawingParts, drawText({x=rect.x+PAD,y=rect.y+PAD+22,w=W-2*PAD,h=20},
    "Segure SPACE para ativar • Soltou, some", 13, subColor, "left"))
  local startY = rect.y + PAD + 58
  local y = startY
  for row = 1, #LAYOUT do
    local x = rect.x + PAD
    for col = 1, #LAYOUT[row] do
      local topLabel, bottomLabel = LAYOUT[row][col][1], LAYOUT[row][col][2]
      table.insert(drawingParts, drawRoundedRect({x=x, y=y, w=KEY_W, h=KEY_H}, 8))
      table.insert(drawingParts, drawText({x=x, y=y+2, w=KEY_W, h=KEY_H/2}, topLabel, 16))
      table.insert(drawingParts, drawText({x=x, y=y+KEY_H/2-2, w=KEY_W, h=KEY_H/2}, bottomLabel, 16, subColor))
      x = x + KEY_W + GAP_X
    end
    y = y + KEY_H + GAP_Y
  end
end
local function drawingShow()
  if not drawingParts then makeDrawing() end
  local rect = frameForCenter(W,H)
  local idx = 1
  drawingParts[idx]:setFrame(rect); idx=idx+1
  drawingParts[idx]:setFrame({x=rect.x+PAD,y=rect.y+PAD,w=W-2*PAD,h=24}); idx=idx+1
  drawingParts[idx]:setFrame({x=rect.x+PAD,y=rect.y+PAD+22,w=W-2*PAD,h=20}); idx=idx+1
  local startY = rect.y + PAD + 58
  local y = startY
  for row = 1, #LAYOUT do
    local x = rect.x + PAD
    for col = 1, #LAYOUT[row] do
      drawingParts[idx]:setFrame({x=x, y=y, w=KEY_W, h=KEY_H}); idx=idx+1
      drawingParts[idx]:setFrame({x=x, y=y+2, w=KEY_W, h=KEY_H/2}); idx=idx+1
      drawingParts[idx]:setFrame({x=x, y=y+KEY_H/2-2, w=KEY_W, h=KEY_H/2}); idx=idx+1
      x = x + KEY_W + GAP_X
    end
    y = y + KEY_H + GAP_Y
  end
  for _,d in ipairs(drawingParts) do d:show() end
end
local function drawingHide() if drawingParts then for _,d in ipairs(drawingParts) do d:hide() end end end

------------------------------------------------------------
-- API (URL) + Recentralizar
------------------------------------------------------------
local function showOverlay() if HAS_CANVAS then canvasShow() else drawingShow() end end
local function hideOverlay()
  ensureMouseUp()
  if HAS_CANVAS then canvasHide() else drawingHide() end
end
hs.urlevent.bind("halfq", function(_, params)
  if not params then return end
  local show = params["show"]
  if show == "1" then showOverlay() elseif show == "0" then hideOverlay() end
  local mouse = params["mouse"]
  if mouse == "down" then ensureMouseDown() elseif mouse == "up" then ensureMouseUp() end
end)
hs.screen.watcher.new(function()
  if HAS_CANVAS then if canvasOverlay and canvasOverlay:isShowing() then canvasOverlay:frame(frameForCenter(W,H)) end end
end):start()

------------------------------------------------------------
-- TRAINER DE RITMO (HUD + metrônomo + erro Δms)
------------------------------------------------------------
local trainer = { on=false, bpm=80, timer=nil, beat=0, lastBeatAt=hs.timer.secondsSinceEpoch() }
local ping = hs.sound.getByName("Pop")
local HUD = hs.canvas.new({x=20,y=40,w=160,h=70})
HUD:level(hs.canvas.windowLevels.status)
HUD[1] = {type="rectangle", fillColor={alpha=0.8,red=0,green=0,blue=0}, roundedRectRadii={xRadius=10,yRadius=10}, frame={x=0,y=0,w=160,h=70}}
HUD[2] = {type="text", text="BPM: 80", textSize=18, textColor={white=1}, frame={x=12,y=8,w=136,h=24}, textAlignment="left"}
HUD[3] = {type="text", text="Δ: — ms", textSize=16, textColor={white=1}, frame={x=12,y=36,w=136,h=24}, textAlignment="left"}
local MAP = { ["`"]="=", ["1"]="0", ["2"]="9", ["3"]="8", ["4"]="7", ["5"]="6",
  Q="P", W="O", E="I", R="U", T="Y", A=";", S="L", D="K", F="J", G="H",
  Z="/", X=".", C=",", V="M", B="N", ["-"]="[", ["="]="]", Tab="\\" }
local interested = {}; for k,_ in pairs(MAP) do interested[k]=true end
local codeToName = {}; for name, code in pairs(hs.keycodes.map) do if type(name)=="string" and type(code)=="number" then codeToName[code]=name end end
local function normName(n) if not n then return nil end if n=="minus" then return "-" end if n=="equal" then return "=" end if n=="grave" or n=="grave_accent_and_tilde" then return "`" end if n=="tab" then return "Tab" end if #n==1 then return string.upper(n) end return n end
local tapTrainer = hs.eventtap.new({hs.eventtap.event.types.keyDown}, function(ev)
  if not trainer.on then return false end
  local name = normName(codeToName[ev:getKeyCode()])
  if not name or not interested[name] then return false end
  local now = hs.timer.secondsSinceEpoch()
  local secPerBeat = 60.0 / trainer.bpm
  local phase = (now - trainer.lastBeatAt) % secPerBeat
  local err = math.min(phase, secPerBeat - phase) * 1000.0
  HUD[3].text = string.format("Δ: %3.0f ms", err)
  return false
end)
local function updateHUD() HUD[2].text = ("BPM: "..trainer.bpm) end
local function tick()
  trainer.beat = trainer.beat + 1
  trainer.lastBeatAt = hs.timer.secondsSinceEpoch()
  if ping then ping:stop(); ping:play() end
  HUD[1].fillColor = {alpha=0.9,red=0.15,green=0.65,blue=0.20}
  hs.timer.doAfter(0.08, function() HUD[1].fillColor = {alpha=0.8,red=0,green=0,blue=0} end)
end
local function startTrainer()
  if trainer.on then return end
  trainer.on = true
  HUD:show()
  updateHUD()
  tapTrainer:start()
  local interval = 60.0 / trainer.bpm
  trainer.timer = hs.timer.doEvery(interval, tick)
end
local function stopTrainer()
  if not trainer.on then return end
  trainer.on = false
  if trainer.timer then trainer.timer:stop(); trainer.timer=nil end
  tapTrainer:stop()
  HUD:hide()
end
hs.hotkey.bind({"ctrl","alt","cmd"}, "M", function()
  if trainer.on then stopTrainer() else startTrainer() end
end)
hs.hotkey.bind({"ctrl","alt","cmd"}, "up", function()
  trainer.bpm = math.min(240, trainer.bpm + 5)
  if trainer.on then stopTrainer(); startTrainer() else updateHUD() end
end)
hs.hotkey.bind({"ctrl","alt","cmd"}, "down", function()
  trainer.bpm = math.max(30, trainer.bpm - 5)
  if trainer.on then stopTrainer(); startTrainer() else updateHUD() end
end)
