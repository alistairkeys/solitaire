import sdl2_nim/sdl
import sdl2_nim/sdl_image as img

type
  Image* = ref ImageObj

  ImageObj* = object of RootObj
    texture*: sdl.Texture
    width*, height*: int

proc w*(obj: Image): int {.inline.} = obj.width
proc h*(obj: Image): int {.inline.} = obj.height
proc newImage*(): Image = Image(texture: nil, width: 0, height: 0)
proc free*(obj: Image) = sdl.destroyTexture(obj.texture)

proc blend*(obj: Image): sdl.BlendMode =
  var blend: sdl.BlendMode
  if obj.texture.getTextureBlendMode(addr(blend)) == 0:
    return blend
  else:
    return sdl.BlendModeBlend

proc `blend=`*(obj: Image, mode: sdl.BlendMode) {.inline.} =
  discard obj.texture.setTextureBlendMode(mode)

proc alpha*(obj: Image): int =
  var alpha: uint8
  if obj.texture.getTextureAlphaMod(addr(alpha)) == 0:
    return alpha
  else:
    return 255

proc `alpha=`*(obj: Image, alpha: int) =
  discard obj.texture.setTextureAlphaMod(alpha.uint8)


proc calculateDimensions(obj: Image): bool =
  result = true
  var w, h: cint
  if obj.texture.queryTexture(nil, nil, addr(w), addr(h)) != 0:
    sdl.logCritical(sdl.LogCategoryError,
                    "Can't get texture attributes: %s",
                    sdl.getError())
    sdl.destroyTexture(obj.texture)
    return false
  obj.width = w
  obj.height = h

proc loadWithColourKey*(obj: Image, renderer: sdl.Renderer, file: string,
    colour: sdl.Color) =
  var surf = load(file)
  discard surf.setColorKey(1.cint, sdl.mapRGB(surf.format, colour.r, colour.g, colour.b))
  obj.texture = createTextureFromSurface(renderer, surf)
  surf.freeSurface()
  discard obj.calculateDimensions()

# Load image from file
# Return true on success or false, if image can't be loaded
proc load*(obj: Image, renderer: sdl.Renderer,
    file: string): bool {.discardable.} =
  result = true
  obj.texture = renderer.loadTexture(file)
  if obj.texture == nil:
    sdl.logCritical(sdl.LogCategoryError, "Can't load image %s: %s", file,
        img.getError())
    return false

  return obj.calculateDimensions()

proc render*(obj: Image, renderer: sdl.Renderer, x,
    y: int): bool {.discardable.} =
  var rect = sdl.Rect(x: x, y: y, w: obj.width, h: obj.height)
  return renderer.renderCopy(obj.texture, nil, rect.addr) == 0

proc copyRect*(obj: Image, renderer: sdl.Renderer, x, y: int,
    sourceRect: Rect): bool {.discardable.} =
  var rect = sdl.Rect(x: x, y: y, w: sourceRect.w, h: sourceRect.h)
  return renderer.renderCopy(obj.texture, sourceRect.unsafeAddr, rect.addr) == 0

proc copyRect*(obj: Image, renderer: sdl.Renderer, destRect,
    sourceRect: Rect): bool {.discardable.} =
  return renderer.renderCopy(obj.texture, sourceRect.unsafeAddr,
      destRect.unsafeAddr) == 0
