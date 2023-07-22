import std/random
import cardtypes, card, cardpile

type
  Pack* = array[52, Card]

proc initPack*(pack: var Pack) =
  const
    xMargin = 7 # relates to rectangles in the has-all-the-cards image
    yMargin = 7 # relates to rectangles in the has-all-the-cards image
    imageRowIndex: array[CardSuit, int] = [1, 2, 3, 0]

  for i, card in pack.mpairs:
    let value = (i mod cardsInSuit) + 1
    let suit = CardSuit(i div cardsInSuit)
    card = newCard(value, suit,
              (xMargin * value) + ((value - 1) * cardWidth),
              yMargin * (imageRowIndex[suit] + 1) + (imageRowIndex[suit] * cardHeight))

proc assignToStacks*(pack: var Pack, piles: openArray[CardPile]) =

  shuffle pack

  var cardIdx = 0

  block tableu:
    var tableauPiles = piles.findPileOfType(cpTableau)
    assert tableauPiles.len == tableauCount

    for blahIdx in 0 ..< tableauCount:
      for pileIdx in blahIdx ..< tableauCount:
        pack[cardIdx].facing = down
        tableauPiles[pileIdx].addCard pack[cardIdx]
        inc cardIdx

    for pile in tableauPiles:
      assert pile.cards.len > 0
      pile.cards[^1].facing = up

  block stock:
    var wastePile = piles.findPileOfType(cpStock)
    for idx in cardIdx .. pack.high:
      pack[idx].facing = up
      wastePile[0].addCard pack[idx]
