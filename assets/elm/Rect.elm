module Rect exposing (Rect, height, intersects, normalizeTopLeft, width, zero)


type alias Rect =
    { x1 : Float
    , y1 : Float
    , x2 : Float
    , y2 : Float
    }


zero : Rect
zero =
    { x1 = 0, y1 = 0, x2 = 0, y2 = 0 }


intersects : Rect -> Rect -> Bool
intersects rect1 rect2 =
    (max rect1.x1 rect2.x1 < min rect1.x2 rect2.x2)
        && (max rect1.y1 rect2.y1 < min rect1.y2 rect2.y2)


width : Rect -> Float
width rect =
    rect.x2 - rect.x1


height : Rect -> Float
height rect =
    rect.y2 - rect.y1


normalizeTopLeft : Rect -> Rect
normalizeTopLeft rect =
    let
        ( x1, x2 ) =
            if rect.x2 < rect.x1 then
                ( rect.x2, rect.x1 )

            else
                ( rect.x1, rect.x2 )

        ( y1, y2 ) =
            if rect.y2 < rect.y1 then
                ( rect.y2, rect.y1 )

            else
                ( rect.y1, rect.y2 )
    in
    { x1 = x1, y1 = y1, x2 = x2, y2 = y2 }
