import std/[sequtils, with, options]
import cardpile, cardtypes

type
  DragState* = enum nope, mouseHeld, dragging

  DragInfo* = object
    dragging*: DragState
    dragPile*: CardPile
    offsetLeft*, offsetTop*: int
    sourcePile*: CardPile
    cardIndex*: int

proc initDragInfo*(padding: int = 0): DragInfo =
  DragInfo(
    dragging: nope,
    dragPile: CardPile(
      which: cpDrag,
      cards: @[],
      visible: false,
      padding: padding
    ),
    sourcePile: nil,
  )

proc cancelDrag*(dragInfo: var DragInfo) =
  var cards = dragInfo.dragPile.cards
  for card in cards:
    doAssert dragInfo.sourcePile != nil
    dragInfo.sourcePile.addCard card
  dragInfo.dragPile.visible = false
  dragInfo.dragging = nope
  dragInfo.sourcePile = nil

proc markDrag*(dragInfo: var DragInfo, pile: CardPile, x, y: int) =
  ## Mark relevant information in preparation for a drag.  A drag doesn't happen
  ## immediately, only after the mouse is held and moved for a bit.  See also
  ## `beginDrag`.

  if dragInfo.dragging != nope:
    dragInfo.cancelDrag

  let idxOpt = pile.findStackIndex(y)
  doAssert idxOpt.isSome
  let idx = idxOpt.get

  let cardY =
    if idx == 0: pile.top
    else: pile.top + (idx * pile.padding)

  with dragInfo:
    dragging = mouseHeld
    offsetLeft = x - pile.left
    offsetTop = y - cardY
    sourcePile = pile
    cardIndex = idx

  with dragInfo.dragPile:
    left = x - dragInfo.offsetLeft
    top = y - dragInfo.offsetTop

proc beginDrag*(dragInfo: var DragInfo) =
  ## Start a previously marked drag.  This transfers cards from their original
  ## stack onto the draggable stack.

  doAssert(dragInfo.dragging == mouseHeld, "Tried to begin a drag without marking it first!")
  dragInfo.dragging = dragging
  dragInfo.dragPile.visible = true

  doAssert dragInfo.sourcePile != nil

  var cards = dragInfo.sourcePile.cards[dragInfo.cardIndex ..
      dragInfo.sourcePile.cards.high]
  for card in cards:
    dragInfo.dragPile.addCard card

func canDropOnto*(dragInfo: DragInfo, pile: CardPile): bool =
  let draggedCards = dragInfo.dragPile.cards
  if draggedCards.len > 0 and dragInfo.dragging == dragging:
    result = pile.visible and pile.canCardBePlaced(dragInfo.dragPile.cards[0])

func isDraggingCard*(dragInfo: DragInfo, card: Card): bool =
  dragInfo.dragPile.cards.anyIt(it.suit == card.suit and it.value == card.value)

proc dropOnto*(dragInfo: var DragInfo, pile: CardPile) =

  if not dragInfo.canDropOnto(pile):
    dragInfo.cancelDrag
    return

  dragInfo.dragPile.visible = false

  var cards = dragInfo.dragPile.cards
  for card in cards:
    pile.addCard card

  doAssert dragInfo.sourcePile != nil
  if dragInfo.sourcePile != pile and dragInfo.sourcePile.cards.len > 0:
    dragInfo.sourcePile.cards[^1].facing = up

  dragInfo.dragging = nope
  dragInfo.sourcePile = nil
