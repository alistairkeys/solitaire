import sdl2_nim/sdl
import sequtils

type
  InputState* = tuple
    pressed: bool
    tick: uint32

  UIState* = object
    mouseX*, mouseY*, hotItem*, activeItem*: int32
    prevMouseX*, prevMouseY*: int32
    keys*: array[512, InputState]
    mouseButtons*: array[22, bool]


  MouseEvent* = enum
    singleClick
    doubleClick
    mouseDown
    mouseUp
    mouseMove

proc mouseDown*(state: UIState): bool =
  state.mouseButtons.anyIt(it)

proc leftMouseDown*(state: UIState): bool =
  state.mouseButtons[BUTTON_LEFT-1]

proc rightMouseDown*(state: UIState): bool =
  state.mouseButtons[BUTTON_RIGHT-1]

proc prepare(state: var UIState) =

  state.hotItem = 0

  #for i in 0 .. state.mouseButtons.high:
  #  state.mouseButtons[i] = false

  # Retrieve the current state of the mouse
  #(state.prevMouseX, state.prevMouseY) = (state.mouseX, state.mouseY)
  #let mouseBtn = int64(sdl.getMouseState(state.mouseX.addr, state.mouseY.addr))

  #for mb in 1..16:
  #  if (sdl.button(mb) and mouseBtn) > 0:
  #    state.mouseButtons[mb-1] = true

proc keyDown*(state: UIState, which: KeyCode): bool =
  let key = sdl.getScancodeFromKey(which)
  result = state.keys[key].pressed

proc finish(state: var UIState) =
  if not state.mouseDown():
    state.activeItem = 0
  elif state.activeItem == 0:
    state.activeItem = -1

template processUI*(state: var UIState; body: untyped) =
  prepare(state)
  body
  finish(state)
