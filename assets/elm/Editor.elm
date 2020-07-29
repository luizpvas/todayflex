module Editor exposing
    ( Editor
    , addNewDrawingWidget
    , clearSelection
    , init
    , screenToWorld
    , update
    , updateSelection
    , updateWidget
    )

import Point exposing (Point)
import Rect exposing (Rect)
import Selection exposing (Selection)
import Widget exposing (Widget, WidgetId)


type alias Editor =
    { panOffset : Point
    , zoomFactor : Float
    , widgets : List Widget
    , selection : Selection
    }


init : Editor
init =
    { panOffset = { x = 0, y = 0 }
    , zoomFactor = 1.0
    , widgets = []
    , selection = Selection.init
    }


screenToWorld : Editor -> Point -> Point
screenToWorld editor point =
    Point.minus editor.panOffset point
        |> Point.scale (1 / editor.zoomFactor)


update : (Editor -> Editor) -> Editor -> Editor
update fn editor =
    fn editor


clearSelection : Editor -> Editor
clearSelection editor =
    { editor | selection = Selection.init }


updateSelection : Rect -> Editor -> Editor
updateSelection selectionRect editor =
    { editor | selection = Selection.calculateSelection selectionRect editor.widgets }


addNewDrawingWidget : Int -> Point -> Editor -> ( Editor, Int )
addNewDrawingWidget latestId screenPoint editor =
    let
        worldPoint =
            screenToWorld editor screenPoint

        updatedWidgets =
            editor.widgets
                ++ [ { id = latestId
                     , rect = { x1 = worldPoint.x, y1 = worldPoint.y, x2 = worldPoint.x, y2 = worldPoint.y }
                     , render = Widget.Drawing [ worldPoint ]
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
