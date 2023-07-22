import sdl2_nim/sdl
import sdl2_nim/sdl_ttf as ttf
import ../sdlgfx
import ../fonts
import uiobject

const
  defaultLabelWidth* = 90
  defaultLabelHeight* = 30

type
  Label* = ref object of UIObject
    caption: string
    foregroundColour*, backgroundColour*: sdl.Color
    font*: string
    transparent*: bool
    marginX*: int
    marginY*: int

proc newLabel*(caption: string = "", x: int = 0, y: int = 0,
    foregroundColour: sdl.Color = sdl.Color(r: 0, g: 0, b: 0),
    backgroundColour: sdl.Color = sdl.Color(r: 0xC0, g: 0xC0, b: 0xC0),
    transparent: bool = true,
    font: string = "font"): Label =

  var labelId {.global.}: int32 = 2000
  inc labelId

  result = Label(
    id: labelId,
    width: defaultLabelWidth,
    height: defaultLabelHeight,
    caption: caption,
    foregroundColour: foregroundColour,
    backgroundColour: backgroundColour,
    font: font,
    transparent: transparent,
    visible: true,
    marginX: 0,
    marginY: 0
  )
  result.xPos = x
  result.yPos = y


method drawImpl*(self: Label, renderer: sdl.Renderer) =
  let labelRect = sdl.Rect(x: self.x, y: self.y, w: self.width, h: self.height)

  if not self.transparent:
    fillRect(renderer, labelRect, self.backgroundColour)

  var text = getFont(self.font).renderUTF8_Solid(self.caption.cstring,
      self.foregroundColour)

  discard renderer.render(text, labelRect.x + self.marginX, labelRect.y + self.marginY)
  sdl.freeSurface(text)

proc caption*(self: Label): string = self.caption
proc `caption=`*(self: Label, newCaption: string) = self.caption = newCaption

proc foregroundColour*(self: Label): sdl.Color = self.foregroundColour
proc `foregroundColour=`*(self: Label, colour: sdl.Color) = self.foregroundColour = colour
