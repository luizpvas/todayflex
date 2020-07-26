module Widget exposing (Widget, WidgetId, WidgetRender(..), pushPointToDrawing, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Point exposing (Point)
import Rect exposing (Rect)
import Svg
import Svg.Attributes


type alias WidgetId =
    Int


type alias Widget =
    { id : WidgetId
    , rect : Rect
    , render : WidgetRender
    }


type WidgetRender
    = Drawing (List Point)


pushPointToDrawing : Point -> Widget -> Widget
pushPointToDrawing { x, y } widget =
    case widget.render of
        Drawing points ->
            { widget
                | render = Drawing (points ++ [ { x = x, y = y } ])
                , rect =
                    { x1 = Basics.min widget.rect.x1 x
                    , y1 = Basics.min widget.rect.y1 y
                    , x2 = Basics.max widget.rect.x2 x
                    , y2 = Basics.max widget.rect.y2 y
                    }
            }


view : Widget -> Html msg
view widget =
    case widget.render of
        Drawing points ->
            let
                width =
                    widget.rect.x2 - widget.rect.x1

                height =
                    widget.rect.y2 - widget.rect.y1

                polylinePoints =
                    List.map (\point -> String.fromFloat (point.x - widget.rect.x1) ++ "," ++ String.fromFloat (point.y - widget.rect.y1)) points
                        |> String.join " "
            in
            Svg.svg
                [ Svg.Attributes.width (String.fromFloat width ++ "px")
                , Svg.Attributes.height (String.fromFloat height ++ "px")
                , Svg.Attributes.style <| "top: " ++ String.fromFloat widget.rect.y1 ++ "px; left: " ++ String.fromFloat widget.rect.x1 ++ "px;"
                , Svg.Attributes.class "absolute"
                ]
                [ Svg.polyline
                    [ Svg.Attributes.fill "none"
                    , Svg.Attributes.stroke "black"
                    , Svg.Attributes.points polylinePoints
                    ]
                    []
                ]
