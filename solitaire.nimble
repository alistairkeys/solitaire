# Package

version       = "0.1.0"
author        = "Ali Keys"
description   = "Solitaire, the solo card game"
license       = "MIT"
srcDir        = "src"
bin           = @["solitaire"]


# Dependencies

requires "nim >= 1.4.8",
  "sdl2nim >= 2.0.14.3"
