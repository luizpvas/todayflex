module Editor exposing
    ( Editor
    , addNewDrawingWidget
    , clearSelection
    , init
    , update
    , updateSelection
    , updateWidget
    , updateWorld
    )

import Point exposing (Point)
import Selection exposing (Selection)
import Widget exposing (Widget, WidgetId)
import World exposing (World)


type alias Editor =
    { world : World
    , widgets : List Widget
    , selection : Selection
    }


init : Editor
init =
    { world = World.init
    , widgets = []
    , selection = Selection.init
    }


update : (Editor -> Editor) -> Editor -> Editor
update fn editor =
    fn editor


updateWorld : (World -> World) -> Editor -> Editor
updateWorld fn editor =
    { editor | world = fn editor.world }


clearSelection : Editor -> Editor
clearSelection editor =
    { editor | selection = Selection.init }


updateSelection : (List Widget -> Selection -> Selection) -> Editor -> Editor
updateSelection fn editor =
    { editor | selection = fn editor.widgets editor.selection }


addNewDrawingWidget : Int -> Point -> Editor -> ( Editor, Int )
addNewDrawingWidget latestId screenPoint editor =
    let
        worldPoint =
            World.pointScreenToWorld editor.world screenPoint

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
