import sdl2_nim/[sdl, sdl_syswm]
import sdl2_nim/sdl_image as img
import sdl2_nim/sdl_ttf as ttf
import std/json
import fps, fonts #, sounds
import ui/uistate

type
  InitProc* = proc(renderer: sdl.Renderer)
  RenderProc* = proc(renderer: sdl.Renderer)
  UpdateProc* = proc(ui: UIState, renderer: sdl.Renderer)
  DestroyProc* = proc()
  MouseEventProc* = proc(kind: MouseEvent, x, y: int)

  App* = ref AppObj
  AppObj* = object
    window*: sdl.Window
    renderer*: sdl.Renderer
    fpsMgr: FpsManager
    initProc*: InitProc
    renderProc*: RenderProc
    updateProc*: UpdateProc
    destroyProc*: DestroyProc
    mouseEventProc*: MouseEventProc
    ui: UIState

const
  title = "Solitaire"
  screenWidth = 1280
  screenHeight = 720
  windowFlags = 0
  rendererFlags = sdl.RendererAccelerated or sdl.RendererPresentVsync

proc logSystemInfo*(app: App) =

  func subsys(kind: SysWMKind): string =
    case kind
      of SysWM_Unknown: "an unknown system"
      of SysWM_Windows: "Microsoft Windows"
      of SysWM_X11: "X Window System"
      of SysWM_DirectFB: "DirectFB"
      of SysWM_Cocoa: "Apple OS X"
      of SysWM_UIKit: "UIKit"
      of SysWM_Wayland: "Wayland"
      of SysWM_Mir: "Mir"
      of SysWM_WinRT: "Microsoft Windows RT"
      of SysWM_Android: "Android"
      of SysWM_Vivante: "Vivante"
      of SysWM_OS2: "OS/2"
      of SysWM_Haiku: "Haiku"

  var info: SysWMinfo
  version(info.version)
  if getWindowWMInfo(app.window, info.addr):
    echo "This program is running SDL version " &
    $info.version.major.int & "." &
    $info.version.minor.int & "." &
    $info.version.patch.int & " on " & subsys(info.subsystem) & "."
  else:
    echo "Couldn't get window information"

proc width*(app: App): int = screenWidth
proc height*(app: App): int = screenHeight

proc init*(app: App): bool =

  doAssert not app.renderProc.isNil
  doAssert not app.updateProc.isNil

  if sdl.init(sdl.InitVideo) != 0:
    echo "Can't initialize SDL"
    return false

  if img.init(img.InitPng) == 0:
    echo "Can't initialise SDL_Image", img.getError()
    return false

  if ttf.init() != 0:
    echo "Can't initialize SDL_TTF", ttf.getError()

  app.window = sdl.createWindow(
    title,
    sdl.WindowPosUndefined,
    sdl.WindowPosUndefined,
    screenWidth,
    screenHeight,
    windowFlags)

  if app.window == nil:
    echo "Can't create window"
    return false

  app.renderer = sdl.createRenderer(app.window, -1, rendererFlags)
  if app.renderer == nil:
    echo "Can't create renderer"
    return false

  if app.renderer.setRenderDrawColor(84, 172, 84, 255) != 0:
    echo "Can't set draw color"
    return false

  #initSound()

  echo "SDL initialized successfully"
  logSystemInfo(app)

  app.fpsMgr = newFpsManager()

  block loadFonts:
    # Eventually, I'd like to read these at compile time so they're statically
    # linked to the exe.  Worst case, I might have to extract them - it depends
    # on whether SDL TTF allows fonts from memory instead of filenames.

    let fonts = parseJson(readFile("data/fonts/fonts.json"))
    for font in fonts:
      let filename = "data/fonts/" & font["file"].getStr
      let fontName = font["name"].getStr
      echo "Loading font: " & $font

      addFont(fontName, ttf.openFont(filename.cstring, font["size"].getInt))
      if getFont(fontName) == nil:
        sdl.logCritical(sdl.LogCategoryError, "Can't load font: %s",
            ttf.getError())
        return false

  return true

proc events(app: App): bool =
  result = false
  var e: sdl.Event

  template notifyOfMouseEvent(kind: MouseEvent) =
    if not app.mouseEventProc.isNil:
      app.mouseEventProc(kind, e.button.x, e.button.y)

  while sdl.pollEvent(e.addr) != 0:

    if e.kind == sdl.Quit:
      return true

    elif e.kind == sdl.KeyUp:
      let blah = sdl.getScancodeFromKey e.key.keysym.sym
      app.ui.keys[blah.int] = (false, sdl.getTicks())

    elif e.kind == sdl.KeyDown:
      let blah = sdl.getScancodeFromKey e.key.keysym.sym
      if not app.ui.keys[blah.int].pressed:
        app.ui.keys[blah.int] = (true, sdl.getTicks())
      echo "Pressed " & $e.key.keysym.sym

    elif e.kind == sdl.MouseButtonDown:
      app.ui.mouseButtons[e.button.button] = true
      if e.button.clicks != 2: # multiple quick clicks accumulate
        notifyOfMouseEvent(singleClick)
      elif e.button.clicks == 2:
        notifyOfMouseEvent(doubleClick)

    elif e.kind == sdl.MouseMotion:
      (app.ui.prevMouseX, app.ui.prevMouseY) = (app.ui.mouseX, app.ui.mouseY)
      (app.ui.mouseX, app.ui.mouseY) = (e.button.x, e.button.y)
      notifyOfMouseEvent(mouseMove)

    elif e.kind == sdl.MouseButtonUp:
      app.ui.mouseButtons[e.button.button] = false
      notifyOfMouseEvent(mouseUp)

proc mainLoop*(app: App) =

  if not app.initProc.isNil:
    app.initProc(app.renderer)

  var done = false
  while not done:
    app.fpsMgr.applyFrameLimit()

    processUI(app.ui):
      app.updateProc(app.ui, app.renderer)
      app.renderProc(app.renderer)

    app.renderer.renderPresent()
    done = done or events(app)

  if not app.destroyProc.isNil:
    app.destroyProc()

proc exit*(app: App) =
  echo ":: destroying renderer"
  app.renderer.destroyRenderer()
  echo ":: destroying window"
  app.window.destroyWindow()
  echo ":: destroying fonts"
  destroyFonts()
  echo ":: destroying FPS manager"
  app.fpsMgr.free()
  echo ":: destroying TTF"
  ttf.quit()
  echo ":: destroying img"
  img.quit()
  #closeSound()
  echo ":: destroying SDL"
  try:
    sdl.quit()
  except:
    discard # tsk, random errors in DLLs I don't control. Great.
  echo "SDL shutdown completed"

