module Editor exposing (Editor, addNewDrawingWidget, update, updateWidget)

import Point exposing (Point)
import Rect exposing (Rect)
import Widget exposing (Widget, WidgetId)


type alias Editor =
    { panOffset : Point
    , zoomFactor : Float
    , widgets : List Widget
    }


update : (Editor -> Editor) -> Editor -> Editor
update fn editor =
    fn editor


detectSelectionIntersectionWithWidgets : Rect -> Editor -> List Widget
detectSelectionIntersectionWithWidgets selection editor =
    let
        intersects =
            \widget ->
                (max selection.x1 widget.rect.x1 < min selection.x2 widget.rect.x2)
                    && (max selection.y1 widget.rect.y1 < min selection.y2 widget.rect.y2)
    in
    List.filter intersects editor.widgets


addNewDrawingWidget : Int -> Point -> Editor -> ( Editor, Int )
addNewDrawingWidget latestId { x, y } editor =
    let
        updatedWidgets =
            editor.widgets
                ++ [ { id = latestId
                     , rect = { x1 = x, y1 = y, x2 = x, y2 = y }
                     , render = Widget.Drawing [ { x = x, y = y } ]
                     }
                   ]
    in
    ( { editor | widgets = updatedWidgets }, latestId + 1 )


updateWidget : WidgetId -> (Widget -> Widget) -> Editor -> Editor
updateWidget id fn editor =
    let
        updatedWidgets =
            List.map
                (\widget ->
                    if widget.id == id then
                        fn widget

                    else
                        widget
                )
                editor.widgets
    in
    { editor | widgets = updatedWidgets }
