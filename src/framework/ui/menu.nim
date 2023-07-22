import sdl2_nim/sdl
import dimensioned, uistate, uiobject, label, checkbox
import std/[options]

type
  Menu* = ref object of UIObject
    selectedIndex*: int
    selectedCaption: string
    title: Label
    submenu: bool

proc calculateWidth(menu: Menu): int =
  if menu.subMenu:
    result = 2 * defaultLabelWidth
  else:
    result = defaultLabelWidth
    for el in menu.kids:
      if el of Checkbox: result = 2 * defaultLabelWidth

# TODO: figure out a more relevant name for this proc!
proc calculateHeight(menu: var Menu): int =
  result = 0
  let xOffset = if menu.subMenu: defaultLabelWidth else: 0
  if not menu.title.isNil and not menu.submenu:
    inc result, 50
  for el in menu.kids.mitems:
    el.x = menu.x + xOffset
    el.y = menu.y + result
    if el of Checkbox or el of Label:
      inc result, defaultLabelHeight
    elif el of Menu:
      var m = el.Menu
      inc result, calculateHeight(m)

proc newMenu*(title: Option[string], items: seq[UIObject], x, y: int,
    submenu: bool = false): Menu =

  var menuId {.global.}: int32 = 1000
  inc menuId

  result = Menu(
    kids: items,
    id: menuId,
    xPos: x,
    yPos: y,
    visible: true,
    width: 0,
    height: 0,
    submenu: submenu
  )
  if title.isSome:
    result.title = newLabel(title.get, x, y,
        font = if submenu: "font" else: "bigFont")

  result.width = calculateWidth(result)
  result.height = calculateHeight(result)

proc next*(menu: Menu) =
  menu.selectedIndex = (menu.selectedIndex + 1) mod menu.kids.len

proc prev*(menu: Menu) =
  dec menu.selectedIndex
  if menu.selectedIndex < 0:
    menu.selectedIndex = menu.kids.high

method drawImpl*(menu: Menu, renderer: sdl.Renderer) =
  if not menu.title.isNil: menu.title.draw renderer

  menu.selectedCaption = ""

  # TODO: need to figure out how to do the stuff below using concepts
  # ("Captioned"). I'm hoping to avoid having to chuck it all in the base class.

  for idx, obj in menu.kids:
    var col = sdl.Color(r: 0x00, g: 0x00, b: 0x00)

    if menu.selectedIndex == idx:
      menu.selectedCaption =
        if obj of Label: obj.Label.caption
        elif obj of Checkbox: obj.Checkbox.caption
        else: ""
      col = sdl.Color(r: 0xFF, g: 0x00, b: 0x00)

    if obj of Label: obj.Label.foregroundColour = col
    elif obj of Checkbox: obj.Checkbox.foregroundColour = col

proc drawMenu*(ui: UIState, menu: Menu, renderer: sdl.Renderer) =
  menu.draw renderer


method handleInput*(self: Menu, state: var UIState): string =
  {.warning[LockLevel]: off.}

  if inBounds(self, state.mouseX, state.mouseY):
    state.hotItem = self.id
    if state.activeItem <= 0 and state.mouseDown:
      state.activeItem = self.id

    for idx, obj in self.kids:
      if inBounds(obj, state.mouseX, state.mouseY):
        self.selectedIndex = idx
        break

  let currentTicks = sdl.getTicks()

  proc keyPressed(state: var UIState, which: KeyCode,
      delay: uint32 = 100): bool =
    let key = sdl.getScancodeFromKey(which)
    if state.keys[key].pressed:
      result = currentTicks - state.keys[key].tick > delay
      if result: state.keys[key].tick = currentTicks

  if state.keyPressed sdl.K_UP:
    self.prev()
  elif state.keyPressed sdl.K_DOWN:
    self.next()

  if state.keyPressed(sdl.K_RETURN, 0):
    result = self.selectedCaption

  if state.activeItem == self.id and state.hotItem == self.id and
      not state.mouseDown:
    result = self.selectedCaption

  if result.len > 0 and self.kids[self.selectedIndex] of Checkbox:
    self.kids[self.selectedIndex].Checkbox.toggleChecked()

