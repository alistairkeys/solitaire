import std/[unittest, options]
import cardpile, cardtypes, card

suite "Card pile tests":

  proc checkArray(checkMe, expected: openArray[Card]) =
    check checkMe.len == expected.len
    for idx, el in checkMe:
      check el == expected[idx]

  test "addCard - no previous pile":
    var p = CardPile()
    var c = Card()

    check p.cards.len == 0
    p.addCard c
    check c.stack == p
    checkArray(p.cards, [c])

  test "addCard - removed from previous pile - only card":
    var
      p1 = CardPile()
      p2 = CardPile()
      c = Card()

    p1.addCard c
    check c.stack == p1
    checkArray(p1.cards, [c])
    check p2.cards.len == 0

    p2.addCard c
    check c.stack == p2
    checkArray(p2.cards, [c])
    check p1.cards.len == 0

  test "addCard - cards on piles already":
    var
      p1 = CardPile()
      p2 = CardPile()
      c1 = Card()
      c2 = Card()
      c3 = Card()

    p1.addCard c1
    p1.addCard c2
    p2.addCard c3

    checkArray(p1.cards, [c1, c2])
    checkArray(p2.cards, [c3])

    p2.addCard c2
    check c2.stack == p2
    checkArray(p1.cards, [c1])
    checkArray(p2.cards, [c3, c2])

  template pilesForFindPileAt(): array[3, CardPile] =
    [CardPile(left: 4, top: 5, padding: 10, visible: true, cards: @[Card()]),
      CardPile(left: 144, top: 5, padding: 10, visible: true, cards: @[Card(),
          Card()]),
      CardPile(left: 244, top: 5, padding: 10, visible: true, cards: @[Card(),
          Card(), Card()])]

  test "findPileAt - too far to the left":
    var p = pilesForFindPileAt()
    check findPileAt(p, p[0].left - 1, p[0].top) == none CardPile

  test "findPileAt - too far to the right":
    var p = pilesForFindPileAt()
    check findPileAt(p, p[0].left + cardWidth + 1, p[0].top) == none CardPile

  test "findPileAt - too far to the top":
    var p = pilesForFindPileAt()
    check findPileAt(p, p[0].left, p[0].top - 1) == none CardPile

  test "findPileAt - too far to the bottom":
    var p = pilesForFindPileAt()
    check findPileAt(p, p[0].left, p[0].top + cardHeight + 1) == none CardPile
    check findPileAt(p, p[1].left, p[1].top + p[1].padding + cardHeight + 1) == none CardPile
    check findPileAt(p, p[2].left, p[2].top + (2 * p[2].padding) + cardHeight +
        1) == none CardPile

  test "findPileAt - not visible":
    var p = pilesForFindPileAt()
    for pile in p:
      pile.visible = false
    check findPileAt(p, p[0].left, p[0].top + 1) == none CardPile
    check findPileAt(p, p[1].left, p[1].top + 1) == none CardPile
    check findPileAt(p, p[2].left, p[2].top + 1) == none CardPile

  proc isPile(v: Option[CardPile], expected: CardPile) =
    check v.isSome
    check v.get == expected

  test "findPileAt - left edge":
    var p = pilesForFindPileAt()
    isPile(findPileAt(p, p[0].left, p[0].top + 1), p[0])
    isPile(findPileAt(p, p[1].left, p[1].top + 1), p[1])
    isPile(findPileAt(p, p[2].left, p[2].top + 1), p[2])

  test "findPileAt - right edge":
    var p = pilesForFindPileAt()
    isPile(findPileAt(p, p[0].left + cardWidth, p[0].top + 1), p[0])
    isPile(findPileAt(p, p[1].left + cardWidth, p[1].top + 1), p[1])
    isPile(findPileAt(p, p[2].left + cardWidth, p[2].top + 1), p[2])

  test "findPileAt - top edge":
    var p = pilesForFindPileAt()
    isPile(findPileAt(p, p[0].left + 1, p[0].top), p[0])
    isPile(findPileAt(p, p[1].left + 1, p[1].top), p[1])
    isPile(findPileAt(p, p[2].left + 1, p[2].top), p[2])

  test "findPileAt - bottom edge":
    var p = pilesForFindPileAt()
    isPile(findPileAt(p, p[0].left + 1, p[0].top + cardHeight), p[0])
    isPile(findPileAt(p, p[1].left + 1, p[1].top + cardHeight + p[1].padding), p[1])
    isPile(findPileAt(p, p[2].left + 1, p[2].top + cardHeight + p[2].padding +
        p[1].padding), p[2])

  test "findPileAt - empty pile":
    var p = CardPile(left: 4, top: 5, padding: 10, visible: true, cards: @[])
    isPile(findPileAt([p], p.left, p.top), p)
    isPile(findPileAt([p], p.left + 1, p.top), p)
    isPile(findPileAt([p], p.left + cardWidth, p.top), p)
    isPile(findPileAt([p], p.left, p.top + 1), p)
    isPile(findPileAt([p], p.left + 1, p.top + 1), p)
    isPile(findPileAt([p], p.left + cardWidth, p.top + 1), p)
    isPile(findPileAt([p], p.left, p.top + cardHeight), p)
    isPile(findPileAt([p], p.left + 1, p.top + cardHeight), p)
    isPile(findPileAt([p], p.left + cardWidth, p.top + cardHeight), p)

  test "pileHeight - no cards":
    var p = CardPile()
    check p.pileHeight == cardHeight

  test "pileHeight - one card":
    var p = CardPile(padding: 5, cards: @[Card()])
    check p.pileHeight == cardHeight

  test "pileHeight - multiple cards, no padding":
    var p = CardPile(padding: 0, cards: @[Card(), Card(), Card()])
    check p.pileHeight == cardHeight

  test "pileHeight - multiple cards, with padding":
    var p = CardPile(padding: 5, cards: @[Card(), Card(), Card()])
    check p.pileHeight == cardHeight + (2 * p.padding)

  test "findStackIndex - missed above a pile (y too small)":
    var p = CardPile(top: 10, padding: 10, visible: true, cards: @[Card(), Card()])
    check p.findStackIndex(-1) == none int
    check p.findStackIndex(0) == none int
    check p.findStackIndex(9) == none int

  test "findStackIndex - missed below a pile (y too big)":
    var p = CardPile(top: 10, padding: 10, visible: true, cards: @[Card(), Card()])
    check p.findStackIndex(1000) == none int
    check p.findStackIndex(10 + cardHeight + 10) == none int

  proc checkIsValue(v: Option[int], expected: int) =
    check v.isSome
    check v.get == expected

  test "findStackIndex - selecting furthest back card":
    var p = CardPile(top: 5, padding: 10, visible: true, cards: @[Card(), Card(
      ), Card()])
    checkIsValue(p.findStackIndex(5), 0)
    checkIsValue(p.findStackIndex(6), 0)
    checkIsValue(p.findStackIndex(14), 0)

  test "findStackIndex - selecting middle card":
    var p = CardPile(top: 5, padding: 10, visible: true, cards: @[Card(), Card(
      ), Card()])
    checkIsValue(p.findStackIndex(15), 1)
    checkIsValue(p.findStackIndex(16), 1)
    checkIsValue(p.findStackIndex(24), 1)

  test "findStackIndex - selecting closest to front card":
    var p = CardPile(top: 5, padding: 10, visible: true, cards: @[Card(), Card(
      ), Card()])
    checkIsValue(p.findStackIndex(25), 2)
    checkIsValue(p.findStackIndex(26), 2)
    checkIsValue(p.findStackIndex(24 + cardHeight), 2)

  test "findStackIndex - pile with no padding":
    var p = CardPile(top: 5, padding: 10, visible: true, cards: @[Card(), Card(
      ), Card()])
    checkIsValue(p.findStackIndex(25), 2)
    checkIsValue(p.findStackIndex(26), 2)
    checkIsValue(p.findStackIndex(24 + cardHeight), 2)

  test "findCardAt - no cards":
    var p = [CardPile(top: 5, left: 5, padding: 10, visible: true)]
    let res = p.findCardAt(6, 6)
    check res[0].isNone
    check res[1].isNone

  test "findCardAt - no card found":
    var p = [CardPile(top: 5, left: 5, padding: 10, visible: true, cards: @[
        Card(), Card(), Card()])]

    proc checkForMiss(x, y: int) =
      let val = p.findCardAt(x, y)
      check val[0].isNone
      check val[1].isNone

    checkForMiss(0, 0)
    checkForMiss(p[0].left + cardWidth + 1, p[0].top)
    checkForMiss(p[0].left + 1, p[0].top + cardHeight + (p[0].padding * 2))

  test "findCardAt - not visible":
    var p = [CardPile(top: 5, left: 5, padding: 10, visible: false, cards: @[
        Card(), Card(), Card()])]

    proc checkForMiss(x, y: int) =
      let val = p.findCardAt(x, y)
      check val[0].isNone
      check val[1].isNone

    checkForMiss(p[0].left, p[0].top)

  test "findCardAt - found card":
    var p = [CardPile(top: 5, left: 5, padding: 10, visible: true, cards: @[
        Card(), Card(), Card()])]

    proc checkForHit(x, y, expectedIdx: int, expectedCard: Card) =
      let val = p.findCardAt(x, y)
      check val[0].isSome
      check val[0].get == expectedCard
      check val[1].isSome
      check val[1].get == expectedIdx

    checkForHit(p[0].left, p[0].top, 0, p[0].cards[0])
    checkForHit(p[0].left, p[0].top + p[0].padding, 1, p[0].cards[1])
    checkForHit(p[0].left, p[0].top + (2 * p[0].padding), 2, p[0].cards[2])

  test "findSuitHome":
    var piles = @[CardPile(which: cpTableau),
                 CardPile(which: cpHome, suit: hearts),
                 CardPile(which: cpHome, suit: diamonds),
                 CardPile(which: cpHome, suit: clubs),
                 CardPile(which: cpHome, suit: spades)]

    for suit in CardSuit.low .. CardSuit.high:
      check piles.findSuitHome(suit) == piles[suit.ord + 1]

  test "home - not home":
    var
      c = Card()
      p = [CardPile(which: cpStock), CardPile(which: cpTableau), CardPile(
          which: cpWaste), CardPile(which: cpUsedWaste), CardPile(which: cpDrag)]

    for pile in p:
      c.stack = pile
      check not c.home

    c.stack = nil
    check not c.home

  test "home - home":
    var c = Card()
    c.stack = CardPile(which: cpHome)
    check c.home

  test "canCardBePlaced - piles that will not accept cards":

    proc checkPile(which: CardPileType) =
      let pile = CardPile(which: which, visible: true)
      check not pile.canCardbePlaced(newCard(1, hearts))

    checkPile cpStock
    checkPile cpWaste
    checkPile cpDrag
    checkPile cpUsedWaste

  test "canCardBePlaced - tableau - empty":
    var pile = CardPile(which: cpTableau, visible: true)
    var card = newCard(1, hearts)
    for value in CardValue.low .. CardValue.high:
      card.value = value
      check pile.canCardbePlaced(card) == card.isKing

  test "canCardBePlaced - tableau - not empty":
    var
      pile = CardPile(which: cpTableau, visible: true)
      existingCard = newCard(4, clubs)
      cardToPlace = newCard(5, spades)

    pile.addCard existingCard

    # greater value
    for suit in CardSuit.low .. CardSuit.high:
      cardToPlace.suit = suit
      check not pile.canCardBePlaced(cardToPlace)

    # same value
    cardToPlace.value = existingCard.value
    for suit in CardSuit.low .. CardSuit.high:
      cardToPlace.suit = suit
      check not pile.canCardBePlaced(cardToPlace)

    # lesser value (might work)
    cardToPlace.value = existingCard.value - 1
    for suit in CardSuit.low .. CardSuit.high:
      cardToPlace.suit = suit
      let shouldWork = suit in {hearts, diamonds}
      check pile.canCardBePlaced(cardToPlace) == shouldWork

    # lesser value (too low)
    cardToPlace.value = existingCard.value - 2
    for suit in CardSuit.low .. CardSuit.high:
      cardToPlace.suit = suit
      check not pile.canCardBePlaced(cardToPlace)

  test "canCardBePlaced - home":
    var
      pile = CardPile(which: cpHome, visible: true)
      existingCard = newCard(1, clubs)
      theCard = newCard(2, spades)

    # wrong suit
    for suit in CardSuit.low .. CardSuit.high:
      theCard.suit = suit
      theCard.value = 1
      pile.suit = if theCard.suit == CardSuit.high: CardSuit.low else: succ(theCard.suit)
      check not pile.canCardBePlaced(theCard)
      theCard.value = 2
      check not pile.canCardBePlaced(theCard)

    # empty home square
    theCard.value = CardValue.low
    for suit in CardSuit.low .. CardSuit.high:
      theCard.suit = suit
      pile.suit = suit
      check pile.canCardBePlaced(theCard)

    # non-empty home square - not next card
    pile.addCard existingCard
    theCard.value = 3
    for suit in CardSuit.low .. CardSuit.high:
      theCard.suit = suit
      existingCard.suit = suit
      pile.suit = suit
      check not pile.canCardBePlaced(theCard)

    # non-empty home square - next card
    theCard.value = 2
    for suit in CardSuit.low .. CardSuit.high:
      theCard.suit = suit
      existingCard.suit = suit
      pile.suit = suit
      check pile.canCardBePlaced(theCard)

  test "findPileOfType - not found":
    let piles = [CardPile(which: cpStock)]
    check piles.findPileOfType(cpDrag).len == 0

  test "findPileOfType - found":
    let piles = [CardPile(which: cpStock), CardPile(which: cpTableau), CardPile(
        which: cpTableau)]

    var stuff = piles.findPileOfType(cpStock)
    check stuff.len == 1
    check stuff[0] == piles[0]

    stuff = piles.findPileOfType(cpTableau)
    check stuff.len == 2
    check stuff[0] == piles[1]
    check stuff[1] == piles[2]
