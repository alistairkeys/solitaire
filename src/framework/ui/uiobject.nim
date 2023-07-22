import sdl2_nim/sdl
import std/sequtils
import uistate

type
  UIObject* = ref object of RootObj
    xPos*, yPos*, width*, height*: int
    id*: int32
    visible*: bool
    kids*: seq[UIObject]

  #[
  # TODO: make use of this in Menu
  
  Captioned* = concept x
    proc caption*(self: x): string
    proc `caption=`*(self: x, newCaption: string)
    proc foregroundColour*(self: x): sdl.Color
    proc `foregroundColour=`*(self: x, colour: sdl.Color)
  ]#


# https://stackoverflow.com/a/63944011
converter toSeqParent*[T: UIObject](x: seq[T]): seq[UIObject] = x.mapIt(it.UIObject)


method x*(self: UIObject): int {.base.} = self.xPos
method `x=`*(self: UIObject, newX: int) {.base.} =
  let diff = newX - self.xPos
  self.xPos = newX
  for el in self.kids.mitems:
    el.x = el.x + diff

method y*(self: UIObject): int {.base.} = self.yPos
method `y=`*(self: UIObject, newY: int) {.base.} =
  let diff = newY - self.yPos
  self.yPos = newY
  for el in self.kids.mitems:
    el.y = el.y + diff



method drawImpl*(self: UIObject, renderer: sdl.Renderer) {.base,
    locks: "unknown".} =
  discard

method draw*(self: UIObject, renderer: sdl.Renderer) {.base,
    locks: "unknown".} =
  if self.visible:
    drawImpl(self, renderer)
    for obj in self.kids:
      draw(obj, renderer)

method handleInput*(self: UIObject, state: var UIState): string {.base.} =
  discard
