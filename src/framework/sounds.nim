import sdl2_nim/sdl
import sdl2_nim/sdl_mixer as mix
import std/options

type
  Sound = object
    filename: string
    volume: uint8
    loops: int # -1 = loop forever
    chunk: mix.Chunk
    channel: Option[int]

# TODO: music: https://github.com/Vladar4/sdl2_nim/blob/master/examples/ex401_mixer.nim
var
  sounds: seq[Sound] # Switch to Table if we have lots of sounds! This assumes only a few
  enabled = true

proc newSound*(filename: string, volume: uint8 = mix.MAX_VOLUME,
    loops: int = 0): Sound =
  Sound(filename: filename, volume: volume, loops: loops, chunk: nil)

proc initSound*() =
  if mix.openAudio(mix.DefaultFrequency, mix.DefaultFormat, mix.DefaultChannels,
      1024) != 0:
    sdl.logCritical(sdl.LogCategoryError,
        "Can't open mixer with the given audio format: %s", mix.getError())

  if mix.init(mix.InitMP3) == 0:
    sdl.logCritical(sdl.LogCategoryError, "Can't initialize mixer flags: %s",
        mix.getError())

proc play*(sound: var Sound) =
  if enabled:
    if sound.chunk.isNil:
      sound.chunk = mix.loadWAV sound.filename.cstring
    let channel = mix.playChannel(-1, sound.chunk, sound.loops.cint)
    sound.channel = if channel == -1: none int else: some channel.int

proc findSound(filename: string): tuple[snd: Option[Sound], idx: int] =
  ## Finds a sound by its filename.  If the sound is not found, the `idx` result
  ## field will be -1.
  for idx, sound in sounds:
    if sound.filename == filename:
      return (some sound, idx)
  return (none Sound, -1)

proc play*(filename: string) =
  var soundOpt = findSound filename
  if soundOpt.snd.isNone:
    var sound = newSound(filename)
    play sound
    sounds.add sound
  else:
    play soundOpt.snd.get

proc stop*(sound: var Sound) =
  # TODO: this proc is untested, try it out
  let soundOpt = findSound sound.filename
  if soundOpt.snd.isSome:
    sounds.del soundOpt.idx

  if sound.channel.isSome:
    discard mix.haltChannel(sound.channel.get)
    sound.channel = none int

  if not sound.chunk.isNil:
    mix.freeChunk(sound.chunk)
    sound.chunk = nil

proc stop*(filename: string) =

  let soundOpt = findSound filename
  if soundOpt.snd.isSome:
    echo "found sound to stop"
    var sound = soundOpt.snd.get

    if sound.channel.isSome:
      discard mix.haltChannel(sound.channel.get)

    if not sound.chunk.isNil:
      mix.freeChunk(sound.chunk)

    sounds.del soundOpt.idx


proc closeSound*() =

  if enabled:
    echo "Closing sound"

  while mix.init(0) != 0:
    mix.quit()

  let mixNumOpened = mix.querySpec(nil, nil, nil)
  for i in 0 ..< mixNumOpened:
    mix.closeAudio()

  for sound in sounds:
    if not sound.chunk.isNil:
      mix.freeChunk(sound.chunk)

  sounds.reset

proc setEnabled*(value: bool) =
  enabled = value

proc getEnabled*(): bool = enabled
