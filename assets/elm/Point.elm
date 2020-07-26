module Point exposing (Point, minus, scale)


type alias Point =
    { x : Float, y : Float }


minus : Point -> Point -> Point
minus p1 p2 =
    { x = p2.x - p1.x, y = p2.y - p1.y }


scale : Float -> Point -> Point
scale factor point =
    { x = point.x * factor, y = point.y * factor }
