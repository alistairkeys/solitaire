import sdl2_nim/sdl
import sdl2_nim/sdl_ttf as ttf
import fonts

proc render*(renderer: sdl.Renderer; surface: sdl.Surface; x, y: int): bool =
  result = true
  var rect = sdl.Rect(x: x, y: y, w: surface.w, h: surface.h)
  var texture = sdl.createTextureFromSurface(renderer, surface)
  if texture == nil:
    return false

  if renderer.renderCopy(texture, nil, addr(rect)) == 0:
    result = false

  destroyTexture(texture)

#[

# Render transformed texture to screen
proc renderEx(obj: Image, renderer: sdl.Renderer, x, y: int,
              w = 0, h = 0, angle = 0.0, centerX = -1, centerY = -1,
              flip = sdl.FlipNone): bool =
  var
    rect = sdl.Rect(x: x, y: y, w: obj.w, h: obj.h)
    centerObj = sdl.Point(x: centerX, y: centerY)
    center: ptr sdl.Point = nil
  if w != 0: rect.w = w
  if h != 0: rect.h = h
  if not (centerX == -1 and centerY == -1): center = addr(centerObj)
  if renderer.renderCopyEx(obj.texture, nil, addr(rect),
                           angle, center, flip) == 0:
    return true
  else:
    return false
]#

proc fillRect*(renderer: sdl.Renderer; r: sdl.Rect; colour: sdl.Color) =
  var oldColour: sdl.Color
  discard renderer.getRenderDrawColor(oldColour)
  discard renderer.setRenderDrawColor(colour)
  discard sdl.renderFillRect(renderer, r.unsafeAddr)
  discard renderer.setRenderDrawColor(oldColour)

proc drawText*(renderer: sdl.Renderer; x, y: int; textToDraw: string;
    font: string = "font"; colour: sdl.Color = sdl.Color(r: 0, g: 0, b: 0)) =
  var text = getFont(font).renderUTF8_Solid(textToDraw, colour)
  discard renderer.render(text, x, y)
  sdl.freeSurface(text)
