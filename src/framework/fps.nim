import sdl2_nim/sdl

# Based on:
# https://github.com/Vladar4/sdl2_nim/blob/master/examples/ex208_framerate.nim

type
  FpsManager* = ref FpsManagerObj
  FpsManagerObj* = object
    counter, fps: int
    timer: sdl.TimerID
    freq*: uint64
    delta: float
    ticks: uint64 # Ticks counter
    fpsLimit: int

proc fpsTimer(interval: uint32, param: pointer): uint32 {.cdecl.} =
  ## `param` is FpsManager casted to pointer
  let obj = cast[FpsManager](param)
  obj.fps = obj.counter
  obj.counter = 0
  return interval

proc start*(obj: FpsManager) =
  obj.timer = sdl.addTimer(1000, fpsTimer, cast[pointer](obj))

proc newFpsManager*(fpsLimit: int = 100): FpsManager =
  result = FpsManager(counter: 0, fps: 0, timer: 0,
      freq: sdl.getPerformanceFrequency(), delta: 0.0, fpsLimit: fpsLimit,
      ticks: getPerformanceCounter())
  result.start()

proc free*(obj: FpsManager) =
  discard sdl.removeTimer(obj.timer)
  obj.timer = 0

proc fps*(obj: FpsManager): int {.inline.} =
  return obj.fps

proc count*(obj: FpsManager) {.inline.} =
  inc obj.counter

proc applyFrameLimit*(fpsMgr: FpsManager) =
  # Limit FPS
  let spare = uint32(1000 / fpsMgr.fpsLimit) - 1000'u32 * uint32((
      sdl.getPerformanceCounter() - fpsMgr.ticks).float / fpsMgr.freq.float)
  if spare > 0'u32:
    sdl.delay(spare)

  # Get frame duration
  fpsMgr.delta = (sdl.getPerformanceCounter() - fpsMgr.ticks).float /
      fpsMgr.freq.float
  fpsMgr.ticks = sdl.getPerformanceCounter()

