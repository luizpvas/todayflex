module Rect exposing (Rect, height, intersects, left, top, width, zero)


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
    let
        nrect1 =
            normalizeTopLeft rect1

        nrect2 =
            normalizeTopLeft rect2
    in
    (max nrect1.x1 nrect2.x1 < min nrect1.x2 nrect2.x2)
        && (max nrect1.y1 nrect2.y1 < min nrect1.y2 nrect2.y2)


normalizeTopLeft : Rect -> Rect
normalizeTopLeft { x1, y1, x2, y2 } =
    let
        ( nx1, nx2 ) =
            if x1 > x2 then
                ( x2, x1 )

            else
                ( x1, x2 )

        ( ny1, ny2 ) =
            if y1 > y2 then
                ( y2, y1 )

            else
                ( y1, y2 )
    in
    { x1 = nx1, y1 = ny1, x2 = nx2, y2 = ny2 }


width : Rect -> Float
width rect =
    abs (rect.x2 - rect.x1)


height : Rect -> Float
height rect =
    abs (rect.y2 - rect.y1)


top : Rect -> Float
top rect =
    if rect.y1 < rect.y2 then
        rect.y1

    else
        rect.y2


left : Rect -> Float
left rect =
    if rect.x1 < rect.x2 then
        rect.x1

    else
        rect.x2
