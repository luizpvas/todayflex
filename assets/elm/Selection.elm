module Selection exposing (Selection, calculateSelection, init, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Rect exposing (Rect)
import Widget exposing (Widget, WidgetId)


{-| The selection is an abstraction that holds the selected widgets to do something: scale, delete,
draw a big rectangle around the whole shape.
-}
type alias Selection =
    { widgetsIds : List WidgetId
    , selectedWidgetsArea : Rect
    }


init : Selection
init =
    { widgetsIds = []
    , selectedWidgetsArea = Rect.zero
    }


{-| When the user selects two or more widgets, we need to draw a big rectangle around
all widgets. That is, a rectangle that goes from the most-top-left widget to the
most-bottom-right widget. This function calculates this rectangle.
-}
calculateSelection : Rect -> List Widget -> Selection
calculateSelection selectionRect allWidgets =
    let
        selectedWidgets =
            List.filter (\widget -> Rect.intersects selectionRect widget.rect) allWidgets
    in
    { widgetsIds = selectedWidgets |> List.map .id
    , selectedWidgetsArea =
        { x1 = selectedWidgets |> List.map .rect |> List.map .x1 |> List.minimum |> Maybe.withDefault 0
        , y1 = selectedWidgets |> List.map .rect |> List.map .y1 |> List.minimum |> Maybe.withDefault 0
        , x2 = selectedWidgets |> List.map .rect |> List.map .x2 |> List.maximum |> Maybe.withDefault 0
        , y2 = selectedWidgets |> List.map .rect |> List.map .y2 |> List.maximum |> Maybe.withDefault 0
        }
    }


view : Selection -> Html msg
view selection =
    let
        rect =
            selection.selectedWidgetsArea
    in
    case selection.widgetsIds of
        [] ->
            text ""

        _ ->
            div [ class "absolute top-0 left-0 w-screen h-screen overflow-hidden pointer-events-none" ]
                [ div
                    [ class "absolute border border-blue-400"
                    , style "top" (String.fromFloat rect.y1 ++ "px")
                    , style "left" (String.fromFloat rect.x1 ++ "px")
                    , style "width" (String.fromFloat (Rect.width rect) ++ "px")
                    , style "height" (String.fromFloat (Rect.height rect) ++ "px")
                    ]
                    [ div [ class "absolute w-2 h-2 top-0 left-0 -mt-1 -ml-1 bg-blue-400" ] []
                    , div [ class "absolute w-2 h-2 top-0 right-0 -mt-1 -mr-1 bg-blue-400" ] []
                    , div [ class "absolute w-2 h-2 bottom-0 left-0 -mb-1 -ml-1 bg-blue-400" ] []
                    , div [ class "absolute w-2 h-2 bottom-0 right-0 -mb-1 -mr-1 bg-blue-400" ] []
                    ]
                ]
