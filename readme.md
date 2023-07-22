# Solitaire
## What is this?
This is Solitaire, the classic solo cards game where you arrange cards in
ascending order.  Specifically, it's the most well-known variant known as
Klondike Solitaire (USA) or Patience (UK).  This game is written in
[Nim](https://nim-lang.org).

## How do I build it?
Make sure Nim (1.6.x or higher) is downloaded and installed as per the Nim
website's instructions, including a C compiler like MinGW (GCC). You can
check both at the command line using:

    nim -v
    gcc -v

This should display the versions of each if they're installed and available on
the path.

You can install this game using Nimble (a package manager that's installed with
Nim):

    nimble install https://github.com/alistairkeys/solitaire

If you've already cloned the repo, you can build it locally using Nimble from
the project root directory (where the solitaire.nimble file is):

    nimble build -d:release

... which will install the dependencies and compile the source. If you've
already installed the dependencies, you can run the Nim compiler directly:

    cd src
    nim c -r solitaire

You can run the tests with:

    nimble test

## How do I play it?
See https://en.wikipedia.org/wiki/Klondike_(solitaire)

Fill the piles on the right of the screen (the 'foundation' piles) with all
cards of their respective suit.

Click 'Deal' to deal three new cards from the remaining 'waste' cards.  This
cycles around so if you keep seeing the same cards appearing then you either
have to try something new or start a new game.

Drag/drop or double-click the closest-to-you cards from the waste or 'tableau'
piles to move them to the 'foundation' piles.

## Any other notes
The card images are from:
https://commons.wikimedia.org/wiki/File:English_pattern_playing_cards_deck.svg
https://freesvg.org/playing-card-back-red-vector-image

The font is from here (I think... I actually nicked it from another Nim
article):
https://github.com/chrissimpkins/codeface/tree/master/fonts/fixed-sys-excelsior

The 'framework' folder is a copy-and-paste framework I use when mucking around
with new projects.  It'll slowly evolve into something worthwhile, at which
point I'll separate it into its own library, but for now dragons be here.  Or
to put it more clearly, it's half-baked and don't use it as an exemplar for
your own work.

Because this uses SDL2, you'll probably need associated DLLs/SOs.  The Nim
installation has these somewhere and should be on your path so you probably
won't notice either way.

## Improvements / rainy day work
There's a strange bug where the game goes unresponsive as the window gets
dragged, possibly when it's dragged between multiple monitors.  I don't know
if that's my code or SDL.  I tried spamming the project with tests / print
tatements but it didn't track down the issue so short of converting it to
Boxy or Raylib, I'm not sure how to stop this. :(