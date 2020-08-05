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
    , activeSelectionArea : Maybe Rect
    , selectedWidgetsArea : Maybe Rect
    }


init : Selection
init =
    { widgetsIds = []
    , activeSelectionArea = Nothing
    , selectedWidgetsArea = Nothing
    }


{-| Clears the active selection (the rect the user is drawing with their mouse), but keeps selected widgets.
This means the user has stopped selecting and they're ready to _do_ something with the selected widgets: move them,
delete them, etc.
-}
clearActiveSelection : Selection -> Selection
clearActiveSelection selection =
    { selection | activeSelectionArea = Nothing }


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
    , activeSelectionArea = Just selectionRect
    , selectedWidgetsArea =
        Just <|
            { x1 = selectedWidgets |> List.map .rect |> List.map .x1 |> List.minimum |> Maybe.withDefault 0
            , y1 = selectedWidgets |> List.map .rect |> List.map .y1 |> List.minimum |> Maybe.withDefault 0
            , x2 = selectedWidgets |> List.map .rect |> List.map .x2 |> List.maximum |> Maybe.withDefault 0
            , y2 = selectedWidgets |> List.map .rect |> List.map .y2 |> List.maximum |> Maybe.withDefault 0
            }
    }


view : Selection -> Html msg
view selection =
    case selection.selectedWidgetsArea of
        Nothing ->
            text ""

        Just rect ->
            div
                [ class "absolute border border-blue-400"
                , style "cursor" "move"
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
