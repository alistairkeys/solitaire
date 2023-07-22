import sdl2_nim/sdl
import label, uiobject

type
  Checkbox* = ref object of UIObject
    checked: bool

proc checkedToStr(c: bool): string =
  if c: "On" else: "Off"

proc newCheckbox*(checked: bool = false, caption: string = "", x: int = 0,
    y: int = 0, foregroundColour: sdl.Color = sdl.Color(r: 0, g: 0, b: 0),
    backgroundColour: sdl.Color = sdl.Color(r: 0xC0, g: 0xC0, b: 0xC0),
    transparent: bool = true): Checkbox =

  var checkboxId {.global.}: int32 = 3000
  inc checkboxId

  result = Checkbox(
    id: checkboxId,
    width: defaultLabelWidth * 2,
    height: defaultLabelHeight,
    checked: checked,
    visible: true,
    kids: @[
      newLabel(caption, x, y, foregroundColour, backgroundColour, transparent),
      newLabel(checkedToStr(checked), x + defaultLabelWidth, y,
            foregroundColour, backgroundColour, transparent)
    ]
  )
  result.xPos = x
  result.yPos = y

proc checked*(self: Checkbox): bool = self.checked
proc `checked=`*(self: Checkbox, checked: bool) =
  self.checked = checked
  self.kids[1].Label.caption = checkedToStr checked

proc toggleChecked*(self: Checkbox) =
  `checked=`(self, not self.checked)

proc caption*(self: Checkbox): string = self.kids[0].Label.caption
proc `caption=`*(self: Checkbox, newCaption: string) = self.kids[
    0].Label.caption = newCaption

proc foregroundColour*(self: Checkbox): sdl.Color = self.kids[
    0].Label.foregroundColour
proc `foregroundColour=`*(self: Checkbox, colour: sdl.Color) =
  self.kids[0].Label.foregroundColour = colour
  self.kids[1].Label.foregroundColour = colour
