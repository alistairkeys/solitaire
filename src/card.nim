import cardtypes

const
  cardWidth* = 91
  cardHeight* = 137

proc newCard*(value: CardValue, suit: CardSuit, imageX: int = 0,
    imageY: int = 0): Card =
  Card(
    value: value,
    suit: suit,
    stack: nil,
    facing: up,
    imageX: imageX,
    imageY: imageY
  )

func suitColour*(card: Card): string =
  if card.suit in {hearts, diamonds}: "red" else: "black"

func isKing*(card: Card): bool =
  card.value == CardValue.high
