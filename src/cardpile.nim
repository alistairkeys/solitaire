import std/options
import cardtypes, card

type
  DodgyDataDefect = object of Defect

const
  tableauCount* = 7
  maxStackCount* = 7 + tableauCount # stock + waste + used waste + 7 tableu + 4 home squares

proc addCard*(pile: CardPile, card: Card) =
  if card.stack != nil:
    var idxOnOldPile = card.stack.cards.find card
    if idxOnOldPile != -1:
      card.stack.cards.delete idxOnOldPile
  card.stack = pile
  pile.cards.add card

func findPileAt*(piles: openArray[CardPile], x, y: int): Option[CardPile] =
  ## Finds which pile is at the window `x` and `y` coordinates (in pixels).  If
  ## no piles are at the location then none(CardPile) is returned.  Note that
  ## empty piles (without any cards) can be returned (e.g. for use in home
  ## squares when a game starts).
  for pile in piles:
    if pile.visible:
      if x in pile.left .. pile.left + cardWidth:
        let paddedBottom = if pile.cards.len > 0: (pile.padding * (
            pile.cards.len - 1)) else: 0
        if y in pile.top .. pile.top + cardHeight + paddedBottom:
          return some pile

func pileHeight*(pile: CardPile): int =
  ## Calculates the pixels required vertically for a pile of cards (including
  ## padding, if relevant).
  if pile.cards.len == 0: cardHeight
  else: ((pile.cards.len - 1) * pile.padding) + cardHeight

func findStackIndex*(pile: CardPile, pixelY: int): Option[int] =
  ## Finds a card within a pile of cards.  The `y` parameter is in pixels
  ## relative to the window.
  let translatedY = pixelY - pile.top
  if translatedY in 0 ..< pileHeight(pile):
    let yAfterDiv = if pile.padding == 0: pile.cards.len -
        1 else: translatedY div pile.padding
    result = some (min(pile.cards.len - 1, yAfterDiv))

func findCardAt*(piles: openArray[CardPile], pixelX, pixelY: int): (Option[
    Card], Option[int]) =
  let pileOpt = findPileAt(piles, pixelX, pixelY)
  if pileOpt.isSome and pileOpt.get.visible:
    let thePile = pileOpt.get
    let idx = findStackIndex(thePile, pixelY)
    if idx.isSome and idx.get > -1:
      return (some thePile.cards[idx.get], idx)

func findSuitHome*(piles: openArray[CardPile], suit: CardSuit): CardPile =
  for pile in piles:
    if pile.which == cpHome and pile.suit == suit:
      return pile
  raise newException(DodgyDataDefect, "Cannot find home square for suit " & $suit)

func home*(card: Card): bool =
  card.stack != nil and card.stack.which == cpHome

func canCardBePlaced*(pile: CardPile, card: Card): bool =
  if pile.which == cpTableau:
    if pile.cards.len == 0:
      return card.isKing
    let c = pile.cards[^1]
    return c.suitColour != card.suitColour and c.value == card.value + 1

  elif (pile.which == cpHome) and (card.suit == pile.suit):
    if pile.cards.len == 0:
      return card.value == CardValue.low
    return card.value == pile.cards[^1].value + 1

func findPileOfType*(piles: openArray[CardPile], pileType: CardPileType): seq[CardPile] =
  for p in piles:
    if p.which == pileType:
      result.add p
