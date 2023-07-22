import std/[options, random, sequtils, times]
import sdl2_nim/sdl
import framework/sdlapp
import framework/[sdlgfx, sdlimg]
import framework/ui/[dialog, dimensioned, label, uiobject, uistate]
import card, cardpile, cardtypes, dragdrop, pack

#[
Solitaire game logic

This file defines logic for Solitaire (Patience (UK) or Klondike (USA)).
The cards are placed in an array and their relative places on the game board
are stored in piles.

TODO: fix overdraw - if cards aren't closest ones, you only need to draw
      a pile.padding's-worth of the image, not the entire card image.
TODO: remove the sound DLL dependency (if it's there from the framework), see
      if images can be staticRead so final exe is standalone.
]#

const
  # Display-related constants
  cardTopPadding = 20
  sidebarWidth = 45
  imageRowIndex: array[CardSuit, int] = [1, 2, 3, 0]
  backgroundColour = sdl.Color(r: 84, g: 172, b: 84)
  darkBackgroundColour = sdl.Color(r: 84, g: 142, b: 84)
  buttonColour = sdl.Color(r: 192, g: 192, b: 192)
  buttonActiveColour = sdl.Color(r: 255, g: 255, b: 255)
  # End of display-related constants

  stockCardsToDeal = 3

  dealButtonIndex = 0
  newGameButtonIndex = 1
  moveAllButtonIndex = 2

var
  cards: Pack
  piles: array[maxStackCount, CardPile] # 1 stock, 1 waste, 7 stacks, 4 home
  dragInfo: DragInfo
  startTime: DateTime
  victory = false
  victoryDialog: Dialog
  needsNewGame = false
  highlightedPile: Option[CardPile]
  labels: seq[Label]
  buttons: seq[Label]                   # No separate button UI element yet
  cardsImage = newImage()
  cardBackImage = newImage()

randomize()

proc dealStockCards() =

  if victory: return

  if dragInfo.dragging == dragging and dragInfo.sourcePile.which == cpStock:
    dragInfo.cancelDrag
    highlightedPile.reset

  template stock(): CardPile = piles[0]
  template waste(): CardPile = piles[1]
  template usedWaste(): CardPile = piles[2]

  if stock.cards.len == 0 and usedWaste.cards.len != 0:
    # The waste pile becomes the stock pile.  The cadrs are added in reverse
    # order to simulate turning over the cards.
    # TODO: confirm this logic is the right way around
    for idx in countdown(usedWaste.cards.high, 0):
      stock.addCard usedWaste.cards[idx]

  # Move the existing cards to the waste as they're no longer available until
  # the next time we cycle through all the cards
  var wasteCopy = waste.cards
  for card in wasteCopy:
    usedWaste.addCard card

  var stockToMove = stock.cards[0 ..< min(stockCardsToDeal, stock.cards.len)]
  for card in stockToMove:
    waste.addCard card

proc drawGame*(r: sdl.Renderer) =

  template homeSidebarLeft(screenWidth: int): int =
    screenWidth - (cardWidth + sidebarWidth)

  discard r.renderClear()

  block drawNonCardUI:
    fillRect(r, Rect(x: 0, y: 0, w: cardWidth + sidebarWidth, h: 720), darkBackgroundColour)
    fillRect(r, Rect(x: homeSidebarLeft(1280), y: 0, w: cardWidth +
        sidebarWidth, h: 720), darkBackgroundColour)
    for l in labels: l.draw r
    for b in buttons: b.draw r

  block drawCards:
    proc drawSingleCard(card: Card, left, top: int) =
      if card.facing == down:
        render(cardBackImage, r, left, top)
      else:
        let bounds = Rect(x: card.imageX, y: card.imageY, w: cardWidth, h: cardHeight)
        copyRect(cardsImage, r, left, top, bounds)

    proc drawPile(pile: CardPile) =
      var top = pile.top
      if pile.cards.len == 0:
        var colour = if pile.which == cpTableau: darkBackgroundColour else: backgroundColour
        fillRect(r, Rect(x: pile.left, y: pile.top, w: cardWidth,
            h: cardHeight), colour)

        if pile.which == cpHome:
          let bounds = Rect(x: 45, y: 64 + (143 * imageRowIndex[pile.suit]),
              w: 16, h: 23)

          cardsImage.blend = BLENDMODE_MOD
          copyRect(cardsImage, r, pile.left + ((cardWidth div 2) -
              bounds.w div 2), pile.top + ((cardHeight div 2) - bounds.h div 2), bounds)
          cardsImage.blend = BLENDMODE_NONE
      else:
        for idx, card in pile.cards:
          # If the padding is 0 (for home squares), all cards are at the same
          # screen location so only the closest-to-the-screen (highest index)
          # needs drawn.
          if pile.padding != 0 or idx == pile.cards.high:
            drawSingleCard(card, pile.left, top)
          inc top, pile.padding

    proc drawPileHighlight(p: CardPile) =
      var rr, gg, bb, aa: uint8

      discard r.getRenderDrawColor(addr rr, addr gg, addr bb, addr aa)

      let height = p.pileHeight

      template le(): int = p.left
      template ri(): int = p.left + cardWidth - 1
      template to(): int = p.top + height - cardHeight
      template bo(): int = p.top + height - 1

      discard r.setRenderDrawColor(255, 192, 0, 255)
      discard r.renderDrawLine(le, to, le, bo)
      discard r.renderDrawLine(le, bo, ri, bo)
      discard r.renderDrawLine(ri, bo, ri, to)
      discard r.renderDrawLine(ri, to, le, to)

      discard r.setRenderDrawColor(255, 255, 0, 255)
      discard r.renderDrawLine(le + 1, to + 1, le + 1, bo - 1)
      discard r.renderDrawLine(le + 1, bo - 1, ri - 1, bo - 1)
      discard r.renderDrawLine(ri - 1, bo - 1, ri - 1, to + 1)
      discard r.renderDrawLine(ri - 1, to + 1, le + 1, to + 1)

      discard r.setRenderDrawColor(rr, gg, bb, aa)

    for pile in piles:
      if pile.visible:
        drawPile(pile)

    if dragInfo.dragging == dragging:
      if highlightedPile.isSome:
        drawPileHighlight(highlightedPile.get)
      drawPile(dragInfo.dragPile)

  block drawDialogs:
    if victory:
      victoryDialog.draw(r)

proc youWonTheGame() =
  # ... and you just lost The Game.
  if not victory:
    let theTime = max(1, min(999, (now() - startTime).inSeconds))
    let suffix = if theTime == 1: " second" else: " seconds"
    victory = true
    victoryDialog = newDialog(title = "Congratulations", caption = [
        "You won. Well done!", "Time: " & $theTime & suffix], x = (1280 -
            200) div 2,
        y = (720 - 100) div 2, width = 200, height = 100)

proc gameComplete*(): bool =
  cards.allIt(it.stack != nil and it.stack.which == cpHome)

proc newGame*(renderer: sdl.Renderer) =
  const
    # Display-related constants
    labelTop = 68
    firstCardTop = 110
    stockCardLeft = 30
    firstStackLeft = 220
    homeCardPadding = 10
    stackRightMargin = 34
    stackWidthWithPadding = cardWidth + stackRightMargin

  template homeSquareLeft(screenWidth: int): int =
    screenWidth - (cardWidth + sidebarWidth) + (cardWidth div 4)

  needsNewGame = false
  victory = false

  highlightedPile.reset

  var pileIdx = 0
  # Stock - idx 0
  piles[pileIdx] = CardPile(
    which: cpStock,
    visible: false
  )
  inc pileIdx

  # Waste - idx 1
  piles[pileIdx] = CardPile(
    which: cpWaste,
    top: firstCardTop, left: stockCardLeft,
    visible: true,
    padding: cardTopPadding)
  inc pileIdx

  # Used waste - idx 2
  piles[pileIdx] = CardPile(which: cpUsedWaste, visible: false)
  inc pileIdx

  # Stacks - idx 3 to 9 inclusive
  var left = firstStackLeft
  for idx in 1..tableauCount:
    piles[pileIdx] = CardPile(
      which: cpTableau,
      top: firstCardTop, left: left,
      visible: true,
      padding: cardTopPadding
    )
    inc left, stackWidthWithPadding
    inc pileIdx

  # Home - idx 10 to 13 inclusive
  left = homeSquareLeft(1280)
  var nextTop = firstCardTop
  for theSuit in CardSuit.low .. CardSuit.high:
    piles[pileIdx] = CardPile(
      which: cpHome,
      suit: theSuit,
      top: nextTop, left: left,
      visible: true,
      padding: 0
    )
    inc nextTop, cardHeight + homeCardPadding
    inc pileIdx

  initPack cards
  cards.assignToStacks piles

  dealStockCards()

  dragInfo = initDragInfo(cardTopPadding)

  block setupUI:
    if renderer != nil:
      cardsImage.loadWithColourKey(renderer, "data/gfx/cards.png", backgroundColour)
      cardBackImage.loadWithColourKey(renderer, "data/gfx/card_back.png", backgroundColour)

    labels.reset
    buttons.reset

    labels.add newLabel("Waste", piles[1].left + 23, labelTop)

    buttons.add newLabel("Deal", piles[1].left, firstCardTop + (3 *
        cardTopPadding) + cardHeight, backgroundColour = buttonColour,
        transparent = false)
    buttons[dealButtonIndex].marginX = 29
    buttons[dealButtonIndex].marginY = 6

    buttons.add newLabel("New Game", piles[1].left, 16,
        backgroundColour = buttonColour, transparent = false)
    buttons[newGameButtonIndex].marginX = 14
    buttons[newGameButtonIndex].marginY = 6

    buttons.add newLabel("Move All", piles[9].left, firstCardTop + (16 *
        cardTopPadding) + cardHeight, backgroundColour = buttonColour,
        transparent = false)
    buttons[moveAllButtonIndex].marginX = 13
    buttons[moveAllButtonIndex].marginY = 6

    let tableauPiles = piles.findPileOfType(cpTableau)
    for idx, pile in tableauPiles:
      labels.add newLabel("Tableau " & $(idx + 1), pile.left, labelTop)

    labels.add newLabel("Foundation", homeSquareLeft(1280), labelTop)

  startTime = now()

proc destroyGame*() =
  echo ":: destroyGame start"
  cardsImage.free
  cardBackImage.free
  echo ":: destroyGame end"

proc update*(ui: UIState, r: sdl.Renderer) =
  var blah = sdl.getSCanCodeFromKey K_F1
  if ui.keys[blah.int].pressed:
    dealStockCards()

  blah = sdl.getScancodeFromKey K_F2
  if ui.keys[blah.int].pressed or needsNewGame:
    newGame(r)

proc candealStockCards(): bool =
  if not victory:
    var stock = piles.findPileOfType(cpStock)[0]
    var usedWaste = piles.findPileOfType(cpUsedWaste)[0]
    result = stock.cards.len > 0 or usedWaste.cards.len > 0

proc placeOnHomeSquare(card: Card) =
  ## Moves the card to its home card.  This does not check whether the move is
  ## legal - see also `canPlaceOnHomeSquare`.
  let thePile = card.stack
  doAssert thePile != nil

  if thePile != nil and thePile.cards.len > 1:
    thePile.cards[^2].facing = up

  piles.findSuitHome(card.suit).addCard card

  buttons[dealButtonIndex].visible = candealStockCards()

  if gameComplete():
    youWonTheGame()

proc moveAllCards() =

  var keepLooping = true
  var sanity = 0
  while keepLooping:
    keepLooping = false

    inc sanity
    doAssert sanity < 1000

    for pile in piles:
      for idx in countdown(pile.cards.high, 0):
        var card = pile.cards[idx]

        doAssert card.stack != nil
        if card.stack.which != cpHome:
          let sourcePile = card.stack
          let homePile = piles.findSuitHome(card.suit)
          if idx == sourcePile.cards.high:
            if homePile.canCardBePlaced(card):
              keepLooping = true
              card.placeOnHomeSquare()

  if gameComplete():
    youWonTheGame()

proc checkButtonClicks(x, y: int) =
  for idx, b in buttons:
    if b.visible and inBounds(b, x, y):
      if idx == dealButtonIndex and not victory:
        dealStockCards()
      elif idx == newGameButtonIndex:
        needsNewGame = true
      elif idx == moveAllButtonIndex:
        moveAllCards()

proc handleSingleClick*(x, y: int) =
  if not victory:
    let (cardOpt, idx) = piles.findCardAt(x, y)
    if cardOpt.isSome:
      var card = cardOpt.get
      if card.facing == up:
        doAssert card.stack != nil
        if card.stack.which == cpWaste and idx.get != card.stack.cards.high:
          return

        dragInfo.markDrag(card.stack, x, y)

  checkButtonClicks(x, y)

proc handleMouseMove*(x, y: int) =
  if not victory:
    if dragInfo.dragging == mouseHeld:
      dragInfo.beginDrag
      doAssert dragInfo.sourcePile != nil
      highlightedPile = some dragInfo.sourcePile

    if dragInfo.dragging == dragging:
      dragInfo.dragPile.left = x - dragInfo.offsetLeft
      dragInfo.dragPile.top = y - dragInfo.offsetTop
      let possibleDrop = piles.findPileAt(x, y)
      if possibleDrop.isSome:
        if dragInfo.canDropOnto(possibleDrop.get):
          highlightedPile = possibleDrop
        else:
          highlightedPile.reset
      else:
        highlightedPile.reset

  for idx, b in buttons:
    if inBounds(b, x, y) and (not victory or idx == newGameButtonIndex):
      b.backgroundColour = buttonActiveColour
    else:
      b.backgroundColour = buttonColour

proc handleMouseUp*(x, y: int) =

  if victory: return

  var cancelDrag = true
  if dragInfo.dragging == dragging:
    var targetPileOpt = piles.findPileAt(x, y)
    if targetPileOpt.isSome:
      dragInfo.dropOnto(targetPileOpt.get)
      cancelDrag = false

  if cancelDrag:
    dragInfo.cancelDrag
    highlightedPile.reset

  buttons[dealButtonIndex].visible = candealStockCards()

  if gameComplete():
    youWonTheGame()


proc handleDoubleClick*(x, y: int) =
  ## If double-clicking the closest card of the waste or stack piles, the card
  ## will be moved to the home square (if the home square is empty or the
  ## double-clicked card is one greater than what's on the home square).
  ## Double-clicking on the home squares does nothing, nor does double-clicking
  ## on cards that aren't the closest card (highest index for a pile's cards).
  let (cardOpt, idx) = piles.findCardAt(x, y)
  if cardOpt.isSome:
    let card = cardOpt.get
    doAssert card.stack != nil
    if card.stack.which != cpHome:
      let homePile = piles.findSuitHome(card.suit)
      if idx.get == card.stack.cards.high:
        if homePile.canCardBePlaced(card):
          card.placeOnHomeSquare()

  checkButtonClicks(x, y)

proc handleMouseEvent*(mouseEvent: MouseEvent, x, y: int) =
  echo "handleMouseEvent - ", mouseEvent, " x: ", x, ", y: ", y
  case mouseEvent
    of singleClick: handleSingleClick(x, y)
    of doubleClick: handleDoubleClick(x, y)
    of mouseMove: handleMouseMove(x, y)
    of mouseUp: handleMouseUp(x, y)
    else: discard

proc main() =
  var app = App(initProc: newGame,
                renderProc: drawGame,
                updateProc: update,
                destroyProc: destroyGame,
                mouseEventProc: handleMouseEvent)
  if app.init:
    app.mainLoop
  app.exit

when isMainModule:
  echo "Starting..."
  try:
    main()
  except:
    echo "ERROR! ", $getCurrentExceptionMsg()
  finally:
    echo "Finished!"
