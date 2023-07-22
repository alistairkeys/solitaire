const
  cardsInSuit* = 13

type
  FaceDirection* = enum
    down # the back of the card is visible, i.e. can't tell the suit and value
    up   # the front of the card is visible, i.e. the actual suit and value is shown

  CardSuit* = enum
    hearts, diamonds, clubs, spades

  CardValue* = 1..cardsInSuit # ace (1), two, three.. queen, king (13)

  Card* = ref object
    value*: CardValue
    suit*: CardSuit
    stack*: CardPile
    facing*: FaceDirection
    imageX*, imageY*: int

  CardPileType* = enum
    cpStock # Available cards from the deck that can move to waste (24 at the start of the game)
    cpWaste   # between 0 and 3 cards visible to the user that can be used this turn
    cpUsedWaste # cards that were previously on the waste, unavailable until the next rotation
    cpTableau # the main playing area (28 cards at the start of the game)
    cpHome    # the foundation piles (one per card suit)
    cpDrag    # for any cards in the process of a drag-drop

  CardPile* = ref object
    case which*: CardPileType
      of cpHome:
        suit*: CardSuit
      else: discard
    top*, left*, padding*: int # display-related, in pixels
    visible*: bool
    cards*: seq[Card]
