import std/unittest
import pack, cardtypes, cardpile

suite "Pack test":

  test "initPack":
    var pack: Pack
    initPack pack

    proc checkCardValues(theRange: HSlice[int, int], suit: CardSuit) =
      for idx in theRange:
        check pack[idx-1].value == idx - (theRange.a-1)
        check pack[idx-1].suit == suit
        check pack[idx-1].facing == up

    checkCardValues(01 .. 13, hearts)
    checkCardValues(14 .. 26, diamonds)
    checkCardValues(27 .. 39, clubs)
    checkCardValues(40 .. 52, spades)

  test "assignToStacks":
    var pack: Pack
    var stacks: array[maxStackCount, CardPile]

    initPack pack
    for idx, el in stacks.mpairs:
      let which = case idx
        of 0: cpStock
        of 1: cpWaste
        of 2: cpUsedWaste
        of 3..9: cpTableau
        else: cpHome
      el = CardPile(which: which)

    pack.assignToStacks stacks

    block waste:
      var wastePile = stacks.findPileOfType(cpWaste)[0]
      check wastePile.cards.len == 0

    block usedWaste:
      var usedWastePile = stacks.findPileOfType(cpUsedWaste)[0]
      check usedWastePile.cards.len == 0

    block stock:
      var stockPile = stacks.findPileOfType(cpStock)[0]
      check stockPile.cards.len == 24

      for el in stockPile.cards:
        check el.facing == up

      for c in pack[28 .. ^1]:
        check c.facing == up
        check c.stack.which == cpStock

    block tableau:
      var tableauPiles = stacks.findPileOfType(cpTableau)
      check tableauPiles.len == tableauCount
      for idx, pile in tableauPiles:
        check pile.cards.len == idx + 1
        for cardIdx, card in pile.cards:
          let expectedFacing =
            if cardIdx == pile.cards.high: up
            else: down

          check card.facing == expectedFacing
          check card.stack == pile

      for c in pack[0 ..< 28]:
        check c.stack.which == cpTableau

    block home:
      var homePiles = stacks.findPileOfType(cpHome)
      check homePiles.len == 4
      for p in homePiles:
        check p.cards.len == 0
