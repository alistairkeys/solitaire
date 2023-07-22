import sdl2_nim/sdl_ttf as ttf
import std/tables

type
  Fonts* = object
    storedFonts: Table[string, ttf.Font]

var
  instance: Fonts = Fonts(storedFonts: initTable[string, ttf.Font]())

proc addFont*(name: string, font: ttf.Font) =
  instance.storedFonts[name] = font

proc getFont*(name: string): ttf.Font =
  instance.storedFonts[name]

proc destroyFonts*() =
  for thefont in instance.storedFonts.mvalues:
    ttf.closeFont(theFont)
  instance.storedFonts.reset
