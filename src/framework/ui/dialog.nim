import sdl2_nim/sdl
import uiobject, label
import ../sdlgfx

type
  Dialog* = ref object of UIObject
    title: Label
    caption: Label
    backgroundColour: sdl.Color

proc newDialog*(title: string, caption: openArray[string], x, y, width,
    height: int, backgroundColour: sdl.Color = sdl.Color(r: 205, g: 225,
        b: 205)): Dialog =

  var dialogId {.global.}: int32 = 1000
  inc dialogId

  var kids = @[newLabel(title, x, y, font = "bigFont",
      backgroundColour = sdl.Color(r: 198, g: 218, b: 40), transparent = false)]

  var labelTop = y + defaultLabelHeight + 8
  for cap in caption:
    kids.add newLabel(cap, x + 8, labelTop, font = "font")
    inc labelTop, defaultLabelHeight

  kids[0].width = width
  kids[0].marginX = 8

  result = Dialog(
    kids: kids,
    id: dialogId,
    xPos: x,
    yPos: y,
    visible: true,
    width: width,
    height: height,
    backgroundColour: backgroundColour
  )


method drawImpl*(dialog: Dialog, renderer: sdl.Renderer) =

#  dialog.title.draw renderer

  fillRect(renderer, Rect(x: dialog.x, y: dialog.y, w: dialog.width,
      h: dialog.height), dialog.backgroundColour)

  # TODO: need to figure out how to do the stuff below using concepts
  # ("Captioned"). I'm hoping to avoid having to chuck it all in the base class.

  #for idx, obj in dialog.kids:
  #  var col = sdl.Color(r: 0x00, g: 0x00, b: 0x00)
  #
  #  if menu.selectedIndex == idx:
  #    menu.selectedCaption =
  #      if obj of Label: obj.Label.caption
  #      elif obj of Checkbox: obj.Checkbox.caption
  #      else: ""
  #    col = sdl.Color(r: 0xFF, g: 0x00, b: 0x00)
  #
  #  if obj of Label: obj.Label.foregroundColour = col
  #  elif obj of Checkbox: obj.Checkbox.foregroundColour = col

#proc drawDialog*(ui: UIState, dialog: Dialog, renderer: sdl.Renderer) =
#  dialog.draw renderer

