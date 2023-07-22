type
  Dimensioned* = concept obj
    obj.x is int
    obj.y is int
    obj.width is int
    obj.height is int

  Bounds* = object
    x*, y*, width*, height*: int

proc inBounds*(obj: Dimensioned, x, y: int): bool =
  x >= obj.x and
  y >= obj.y and
  x < obj.x + obj.width and
  y < obj.y + obj.height
