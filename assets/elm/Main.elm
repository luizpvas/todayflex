module Main exposing (main)

import Browser
import Browser.Dom
import Browser.Events
import Editor exposing (Editor)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icon
import Json.Decode as Decode exposing (Decoder)
import Lang
import Point exposing (Point)
import Ports
import Task
import Tool exposing (Tool)
import Widget exposing (Widget, WidgetId)



-- CONSTANTS / CONFIG


zoomSmoothFactor : Float
zoomSmoothFactor =
    250.0


minZoomFactor : Float
minZoomFactor =
    0.3


maxZoomFactor : Float
maxZoomFactor =
    4.0



-- MODEL


type Mode
    = Hovering
    | Panning
    | Selecting Point Point
    | Drawing WidgetId


type alias Model =
    { latestId : Int
    , mode : Mode
    , editor : Editor
    , screen : Point
    , selectedTool : Tool
    }


type alias Flags =
    { latestId : Int
    }


init : Flags -> ( Model, Cmd Msg )
init flags =
    ( { latestId = flags.latestId
      , mode = Hovering
      , editor = { panOffset = { x = 0, y = 0 }, zoomFactor = 1.0, widgets = [] }
      , screen = { x = 0, y = 0 }
      , selectedTool = Tool.Move
      }
    , Task.perform GotViewport Browser.Dom.getViewport
    )



-- UPDATE


type Msg
    = GotViewport Browser.Dom.Viewport
    | ShortcutPressed String
    | SelectTool Tool
    | StartPanning
    | ApplyPanningDelta Float Float
    | StopPanning
    | StartSelecting Float Float
    | SelectionMove Float Float
    | StopSelecting
    | ZoomMove Float Float Float
    | StartDrawing Float Float
    | DrawingMove Float Float
    | StopDrawing


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotViewport viewport ->
            ( { model | screen = { x = viewport.scene.width, y = viewport.scene.height } }, Cmd.none )

        ShortcutPressed key ->
            case Tool.toolFromShortcut key of
                Nothing ->
                    ( model, Cmd.none )

                Just tool ->
                    ( { model | selectedTool = tool }, Cmd.none )

        SelectTool tool ->
            ( { model | selectedTool = tool }, Cmd.none )

        StartPanning ->
            ( { model | mode = Panning }, Cmd.none )

        ApplyPanningDelta x y ->
            ( updateEditor
                (\editor ->
                    { editor
                        | panOffset =
                            { x = editor.panOffset.x + x
                            , y = editor.panOffset.y + y
                            }
                    }
                )
                model
            , Cmd.none
            )

        StopPanning ->
            ( { model | mode = Hovering }, Cmd.none )

        StartSelecting x y ->
            ( { model | mode = Selecting { x = x, y = y } { x = x, y = y } }, Cmd.none )

        SelectionMove x y ->
            case model.mode of
                Selecting startPoint _ ->
                    ( { model | mode = Selecting startPoint { x = x, y = y } }, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        StopSelecting ->
            ( { model | mode = Hovering }, Cmd.none )

        ZoomMove x y delta ->
            let
                smoothedDelta =
                    delta / zoomSmoothFactor

                updatedZoomFactor =
                    model.editor.zoomFactor + smoothedDelta

                correctedX =
                    x - model.editor.panOffset.x

                correctedY =
                    y - model.editor.panOffset.y
            in
            ( updateEditor
                (\editor ->
                    { editor
                        | zoomFactor = Basics.min (Basics.max minZoomFactor updatedZoomFactor) maxZoomFactor
                        , panOffset =
                            { x = editor.panOffset.x - (correctedX * smoothedDelta * 1 / editor.zoomFactor)
                            , y = editor.panOffset.y - (correctedY * smoothedDelta * 1 / editor.zoomFactor)
                            }
                    }
                )
                model
            , Cmd.none
            )

        StartDrawing x y ->
            let
                ( updatedEditor, nextId ) =
                    Editor.addNewDrawingWidget model.latestId
                        (Point.scale (1 / model.editor.zoomFactor) (Point.minus model.editor.panOffset { x = x, y = y }))
                        model.editor
            in
            ( { model | editor = updatedEditor, latestId = nextId, mode = Drawing model.latestId }, Cmd.none )

        DrawingMove x y ->
            case model.mode of
                Drawing widgetId ->
                    ( updateEditor
                        (Editor.updateWidget widgetId
                            (Widget.pushPointToDrawing (Point.scale (1 / model.editor.zoomFactor) (Point.minus model.editor.panOffset { x = x, y = y })))
                        )
                        model
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        StopDrawing ->
            ( { model | mode = Hovering }, Cmd.none )


updateEditor : (Editor -> Editor) -> Model -> Model
updateEditor fn model =
    { model | editor = Editor.update fn model.editor }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Ports.shortcutPressed ShortcutPressed
        ]



-- GLOBAL EVENTS


globalEvents : Model -> List (Attribute Msg)
globalEvents model =
    case model.mode of
        Hovering ->
            let
                clickDecoder =
                    Decode.field "which" Decode.int
                        |> Decode.andThen
                            (\code ->
                                case code of
                                    1 ->
                                        case model.selectedTool of
                                            Tool.Move ->
                                                Decode.map2 StartSelecting
                                                    (Decode.field "pageX" Decode.float)
                                                    (Decode.field "pageY" Decode.float)

                                            Tool.Pencil ->
                                                Decode.map2 StartDrawing
                                                    (Decode.field "pageX" Decode.float)
                                                    (Decode.field "pageY" Decode.float)

                                    2 ->
                                        Decode.succeed StartPanning

                                    _ ->
                                        Decode.fail "unknown button"
                            )

                zoomWheelDecoder =
                    Decode.field "ctrlKey" Decode.bool
                        |> Decode.andThen
                            (\ctrlKey ->
                                if ctrlKey then
                                    Decode.map3 ZoomMove
                                        (Decode.field "pageX" Decode.float)
                                        (Decode.field "pageY" Decode.float)
                                        (Decode.field "deltaY" Decode.float |> Decode.map (\v -> v * -1))

                                else
                                    Decode.fail "ctrlKey not pressed"
                            )
            in
            [ preventDefaultOn "mousedown" (Decode.map alwaysPreventDefault clickDecoder)
            , preventDefaultOn "wheel" (Decode.map alwaysPreventDefault zoomWheelDecoder)
            ]

        Panning ->
            let
                deltaDecoder =
                    Decode.map2 ApplyPanningDelta
                        (Decode.field "movementX" Decode.float)
                        (Decode.field "movementY" Decode.float)
            in
            [ preventDefaultOn "mouseup" (Decode.map alwaysPreventDefault (Decode.succeed StopPanning))
            , preventDefaultOn "mousemove" (Decode.map alwaysPreventDefault deltaDecoder)
            ]

        Selecting _ _ ->
            let
                selectionDecoder =
                    Decode.map2 SelectionMove
                        (Decode.field "pageX" Decode.float)
                        (Decode.field "pageY" Decode.float)
            in
            [ preventDefaultOn "mousemove" (Decode.map alwaysPreventDefault selectionDecoder)
            , preventDefaultOn "mouseup" (Decode.map alwaysPreventDefault (Decode.succeed StopSelecting))
            ]

        Drawing widgetId ->
            let
                drawingDecoder =
                    Decode.map2 DrawingMove
                        (Decode.field "pageX" Decode.float)
                        (Decode.field "pageY" Decode.float)
            in
            [ preventDefaultOn "mousemove" (Decode.map alwaysPreventDefault drawingDecoder)
            , preventDefaultOn "mouseup" (Decode.map alwaysPreventDefault (Decode.succeed StopDrawing))
            ]


alwaysPreventDefault : msg -> ( msg, Bool )
alwaysPreventDefault msg =
    ( msg, True )



-- VIEW


view : Model -> Html Msg
view model =
    div ([ class "bg-gray-200 min-h-screen overflow-hidden", viewCursorStyle model ] ++ globalEvents model) [ viewPage model ]


viewPage : Model -> Html Msg
viewPage model =
    div []
        [ viewBlueprintPattern model.editor
        , viewEditor model
        , viewToolbar model
        , viewSelection model.mode
        ]


viewToolbar : Model -> Html Msg
viewToolbar model =
    div [ class "absolute top-0 right-0 mt-2 mr-2 flex items-center" ]
        [ div [ class "bg-gray-600 text-white py-2 pl-4 pr-12 rounded-full -mr-10 shadow-md" ]
            [ text "Hello"
            ]
        , div [ class "bg-white rounded-full py-2 px-4 space-x-2 flex items-center shadow-md" ]
            [ viewToolbarButton model.selectedTool Tool.Move (Icon.cursor "w-4")
            , viewToolbarButton model.selectedTool Tool.Pencil (Icon.pencil "w-4")
            ]
        ]


viewToolbarButton : Tool -> Tool -> Html Msg -> Html Msg
viewToolbarButton selectedTool tool icon =
    let
        className =
            if selectedTool == tool then
                "flex items-center bg-blue-600 text-white rounded-md p-1"

            else
                "flex items-center hover:bg-gray-300 rounded-md p-1"
    in
    button [ class className, onClick (SelectTool tool) ]
        [ icon
        , span [ class "border text-xs leading-none p-px rounded" ] [ text (Tool.toolToShortcut tool) ]
        ]


viewEditor : Model -> Html Msg
viewEditor model =
    div
        ([ class "relative w-4 h-4 overflow-visible"
         ]
            ++ viewPanOffsetAndZoomStyle model
        )
        (List.map Widget.view model.editor.widgets)


viewBlueprintPattern : Editor -> Html Msg
viewBlueprintPattern editor =
    let
        backgroundPosition1 =
            String.fromFloat (-2 + editor.panOffset.x)
                ++ "px "
                ++ String.fromFloat (-2 + editor.panOffset.y)
                ++ "px"

        backgroundPosition2 =
            String.fromFloat (-1 + editor.panOffset.x)
                ++ "px "
                ++ String.fromFloat (-1 + editor.panOffset.y)
                ++ "px"

        backgroundPosition =
            style "background-position" (backgroundPosition1 ++ ", " ++ backgroundPosition1 ++ ", " ++ backgroundPosition2 ++ ", " ++ backgroundPosition2)

        backgroundSize1 =
            String.fromFloat (100 * editor.zoomFactor)
                ++ "px "
                ++ String.fromFloat (100 * editor.zoomFactor)
                ++ "px"

        backgroundSize2 =
            String.fromFloat (20 * editor.zoomFactor)
                ++ "px "
                ++ String.fromFloat (20 * editor.zoomFactor)
                ++ "px"

        backgroundSize =
            style "background-size" (backgroundSize1 ++ ", " ++ backgroundSize1 ++ ", " ++ backgroundSize2 ++ ", " ++ backgroundSize2)
    in
    div [ class "absolute top-0 left-0 w-screen h-screen blueprint-pattern", backgroundPosition, backgroundSize ] []


viewSelection : Mode -> Html Msg
viewSelection mode =
    case mode of
        Selecting start end ->
            let
                ( top, height ) =
                    if end.y > start.y then
                        ( start.y, end.y - start.y )

                    else
                        ( end.y, start.y - end.y )

                ( left, width ) =
                    if end.x > start.x then
                        ( start.x, end.x - start.x )

                    else
                        ( end.x, start.x - end.x )

                position =
                    [ style "top" (String.fromFloat top ++ "px")
                    , style "left" (String.fromFloat left ++ "px")
                    , style "width" (String.fromFloat width ++ "px")
                    , style "height" (String.fromFloat height ++ "px")
                    ]
            in
            div [ class "absolute top-0 left-0 w-screen h-screen overflow-hidden pointer-events-none" ]
                [ div ([ class "absolute border border-blue-400 bg-blue-200" ] ++ position) []
                ]

        _ ->
            text ""


viewPanOffsetAndZoomStyle : Model -> List (Attribute msg)
viewPanOffsetAndZoomStyle model =
    let
        translate =
            "translate(" ++ String.fromFloat model.editor.panOffset.x ++ "px, " ++ String.fromFloat model.editor.panOffset.y ++ "px)"

        scale =
            "scale(" ++ String.fromFloat model.editor.zoomFactor ++ ")"
    in
    [ style "transform" (translate ++ " " ++ scale), style "transform-origin" "0px 0px" ]


viewCursorStyle : Model -> Attribute msg
viewCursorStyle model =
    case model.selectedTool of
        Tool.Move ->
            case model.mode of
                Hovering ->
                    style "cursor" "default"

                Panning ->
                    style "cursor" "grabbing"

                Selecting _ _ ->
                    style "cursor" "default"

                Drawing _ ->
                    style "cursor" "crosshair"

        Tool.Pencil ->
            style "cursor" "crosshair"


viewLoading : Html Msg
viewLoading =
    div [ class "w-screen h-screen flex items-center justify-center" ]
        [ div [ class "flex items-center" ]
            [ div [ class "lds-ellipsis" ] [ div [] [], div [] [], div [] [], div [] [] ]
            , text (Lang.t "Loading...")
            ]
        ]



-- MAIN


main : Program Flags Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
