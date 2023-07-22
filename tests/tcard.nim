import std/unittest
import cardtypes, card

suite "Card tests":

  test "suitColour":
    proc checkSuitColour(suit: CardSuit, wanted: string) =
      let card = Card(suit: suit)
      check card.suitColour == wanted

    checkSuitColour(hearts, "red")
    checkSuitColour(diamonds, "red")
    checkSuitColour(spades, "black")
    checkSuitColour(clubs, "black")

  test "isKing":
    for suit in CardSuit.low .. CardSuit.high:
      var card = Card(suit: suit, value: CardValue.high)
      check card.isKing
      for value in CardValue.low .. pred(CardValue.high):
        card.value = value
        check not card.isKing
