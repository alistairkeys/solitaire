import std/unittest
import dragdrop, cardpile, cardtypes, card

suite "Drag drop unit tests":

  test "markDrag - no existing drag":
    var
      theCard = Card(value: 2, suit: hearts)
      pile = CardPile(cards: @[])
      di = initDragInfo()

    pile.addCard theCard
    di.markDrag(pile, 5, 6)

    check di.dragging == mouseHeld
    check di.dragPile.cards.len == 0
    check di.offsetLeft == 5
    check di.offsetTop == 6
    check di.sourcePile == pile
    check di.cardIndex == 0
    check pile.cards.len == 1

  test "markDrag - closer card":
    var
      theCard1 = Card(value: 2, suit: hearts)
      theCard2 = Card(value: 1, suit: clubs)
      pile = CardPile(cards: @[], top: 0, left: 0, padding: 10)
      di = initDragInfo()

    pile.addCard theCard1
    pile.addCard theCard2
    di.markDrag(pile, 5, cardHeight + 1)
    check di.cardIndex == 1

  test "markDrag - cancels existing drag":
    var
      theCard1 = Card(value: 2, suit: hearts)
      theCard2 = Card(value: 3, suit: clubs)
      pile1 = CardPile()
      pile2 = CardPile()
      di = initDragInfo()

    pile1.addCard theCard1
    pile2.addCard theCard2

    di.markDrag(pile1, 5, 6)
    di.beginDrag()
    di.markDrag(pile2, 6, 7)

    check di.dragging == mouseHeld
    check di.dragPile.cards.len == 0
    check di.offsetLeft == 6
    check di.offsetTop == 7
    check di.sourcePile == pile2
    check di.cardIndex == 0

    check pile1.cards.len == 1
    check pile1.cards[0] == theCard1
    check theCard1.stack == pile1

    check pile2.cards.len == 1
    check pile2.cards[0] == theCard2
    check theCard2.stack == pile2

  proc beginDragShouldTriggerAssertion(state: DragState) =
    var di = initDragInfo()
    di.dragging = state
    try:
      di.beginDrag()
      fail()
    except
      AssertionDefect: discard # expected the error

  test "beginDrag - no marked drag":
    beginDragShouldTriggerAssertion(nope)

  test "beginDrag - already dragging":
    beginDragShouldTriggerAssertion(dragging)

  test "beginDrag - top card":
    var
      theCard = Card(value: 2, suit: hearts)
      pile = CardPile()
      di = initDragInfo()

    pile.addCard theCard
    di.markDrag(pile, 5, 6)
    di.beginDrag()

    check di.dragging == dragging
    check di.dragPile.cards.len == 1
    check di.dragPile.cards[0] == theCard
    check di.dragPile.visible
    check di.offsetLeft == 5
    check di.offsetTop == 6
    check di.sourcePile == pile
    check di.cardIndex == 0
    check pile.cards.len == 0

  test "cancelDrag - not dragging":
    var dragInfo = initDragInfo()
    try:
      dragInfo.cancelDrag()
    except:
      fail()

  test "cancelDrag - marked":
    var
      dragInfo = initDragInfo()
      theCard = Card(suit: hearts, value: 1)
      sourcePile = CardPile()

    sourcePile.addCard theCard
    dragInfo.markDrag(sourcePile, 1, 2)
    dragInfo.cancelDrag

    check dragInfo.dragging == nope
    check dragInfo.sourcePile.isNil
    check dragInfo.dragPile.cards.len == 0
    check not dragInfo.dragPile.visible

    check theCard.stack == sourcePile
    check sourcePile.cards.len == 1
    check sourcePile.cards[0] == theCard

  test "cancelDrag - dragging":
    var
      dragInfo = initDragInfo()
      theCard = Card(suit: hearts, value: 1)
      sourcePile = CardPile()

    sourcePile.addCard theCard
    dragInfo.markDrag(sourcePile, 1, 2)
    dragInfo.beginDrag
    dragInfo.cancelDrag

    check dragInfo.dragging == nope
    check dragInfo.sourcePile.isNil
    check dragInfo.dragPile.cards.len == 0
    check not dragInfo.dragPile.visible

    check theCard.stack == sourcePile
    check sourcePile.cards.len == 1
    check sourcePile.cards[0] == theCard

  test "canDropOnto - not dragging":
    var dragInfo = initDragInfo()
    var pile = CardPile()
    check not dragInfo.canDropOnto(pile)

  test "canDropOnto - drop onto new pile":
    var
      dragInfo = initDragInfo()
      theCard = newCard(CardValue.high, hearts)
      pile1 = CardPile(which: cpTableau)
      pile2 = CardPile(which: cpTableau, visible: true)

    pile1.addCard theCard
    dragInfo.markDrag(pile1, 0, 0)
    dragInfo.beginDrag
    check dragInfo.canDropOnto(pile2)

    test "canDropOnto - drop onto hidden pile":
      var
        dragInfo = initDragInfo()
        theCard = newCard(CardValue.high, hearts)
        pile1 = CardPile(which: cpTableau)
        pile2 = CardPile(which: cpTableau, visible: false)

      pile1.addCard theCard
      dragInfo.markDrag(pile1, 0, 0)
      dragInfo.beginDrag
      check not dragInfo.canDropOnto(pile2)

  test "canDropOnto - drop onto original pile":
    var
      dragInfo = initDragInfo()
      theCard = newCard(CardValue.high, hearts)
      pile = CardPile(which: cpTableau, visible: true)

    pile.addCard theCard
    dragInfo.markDrag(pile, 0, 0)
    dragInfo.beginDrag
    check dragInfo.canDropOnto(pile)

  test "isDraggingCard - empty drag pile":
    var
      c = Card(suit: hearts, value: 1)
      di = initDragInfo()

    check not isDraggingCard(di, c)

  test "isDraggingCard - pile doesn't contain card":
    var
      c = Card(suit: hearts, value: 1)
      c2 = Card(suit: clubs, value: 2)
      di = initDragInfo()

    di.dragPile.addCard c2
    check not isDraggingCard(di, c)

  test "isDraggingCard - pile has card of same value, different suit":
    var
      c = Card(suit: hearts, value: 1)
      c2 = Card(suit: clubs, value: 1)
      di = initDragInfo()

    di.dragPile.addCard c2
    check not isDraggingCard(di, c)

  test "isDraggingCard - pile has card of same suit, different value":
    var
      c = Card(suit: hearts, value: 1)
      c2 = Card(suit: hearts, value: 2)
      di = initDragInfo()

    di.dragPile.addCard c2
    check not isDraggingCard(di, c)

  test "isDraggingCard - pile contains card (first element)":
    var
      c = Card(suit: hearts, value: 1)
      c2 = Card(suit: clubs, value: 2)
      di = initDragInfo()

    di.dragPile.addCard c
    di.dragPile.addCard c2
    check isDraggingCard(di, c)

  test "isDraggingCard - pile contains card (last element)":
    var
      c = Card(suit: hearts, value: 1)
      c2 = Card(suit: clubs, value: 2)
      di = initDragInfo()

    di.dragPile.addCard c2
    di.dragPile.addCard c
    check isDraggingCard(di, c)

  test "dropOnto - not dragging":
    var
      dragInfo = initDragInfo()
      pile = CardPile(which: cpTableau)

    dragInfo.dropOnto(pile)
    check dragInfo.dragging == nope
    check dragInfo.sourcePile.isNil

  test "dropOnto - different pile than source":
    var
      dragInfo = initDragInfo()
      theCard1 = newCard(CardValue.high, hearts)
      theCard2 = newCard(pred(CardValue.high), clubs)
      theCard3 = newCard(CardValue.high, diamonds)
      pile1 = CardPile(which: cpTableau, padding: 10)
      pile2 = CardPile(which: cpTableau, padding: 10, visible: true)

    theCard1.facing = down
    theCard2.facing = up
    theCard3.facing = up

    pile1.addCard theCard1
    pile1.addCard theCard2
    pile2.addCard theCard3

    dragInfo.markDrag(pile1, 0, cardHeight + 1)
    dragInfo.beginDrag
    dragInfo.dropOnto(pile2)

    check dragInfo.dragging == nope
    check dragInfo.sourcePile.isNil

    check pile1.cards.len == 1
    check pile1.cards[0] == theCard1
    check pile1.cards[0].facing == up

    check pile2.cards.len == 2
    check pile2.cards[0] == theCard3
    check pile2.cards[0].facing == up
    check pile2.cards[1] == theCard2
    check pile2.cards[1].facing == up

  test "dropOnto - same pile as source":
    var
      dragInfo = initDragInfo()
      theCard1 = newCard(CardValue.high, hearts)
      theCard2 = newCard(pred(CardValue.high), clubs)
      pile = CardPile(which: cpTableau)

    theCard1.facing = down
    theCard2.facing = up
    pile.addCard theCard1
    pile.addCard theCard2

    dragInfo.markDrag(pile, 0, 0)
    dragInfo.beginDrag
    dragInfo.dropOnto(pile)

    check dragInfo.dragging == nope
    check dragInfo.sourcePile.isNil

    check pile.cards.len == 2
    check pile.cards[0].facing == down
    check pile.cards[0] == theCard1
    check pile.cards[0].stack == pile

    check pile.cards[1].facing == up
    check pile.cards[1] == theCard2
    check pile.cards[0].stack == pile
