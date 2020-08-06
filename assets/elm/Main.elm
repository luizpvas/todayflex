module Main exposing (main)

import Browser
import Browser.Dom
import Editor exposing (Editor)
import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (..)
import Icon
import Json.Decode as Decode exposing (Decoder)
import Lang
import Point exposing (Point)
import Ports
import Rect exposing (Rect)
import Selection
import Task
import Tool exposing (Tool)
import Widget exposing (Widget, WidgetId)
import World exposing (World)



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
    | Selecting Rect
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
      , editor = Editor.init
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
            let
                updatedPan =
                    { x = model.editor.world.pan.x + x, y = model.editor.world.pan.y + y }
            in
            ( updateEditor (Editor.updateWorld (World.updatePan updatedPan)) model, Cmd.none )

        StopPanning ->
            ( { model | mode = Hovering }, Cmd.none )

        StartSelecting screenX screenY ->
            let
                worldPoint =
                    World.pointScreenToWorld model.editor.world { x = screenX, y = screenY }
            in
            ( { model | mode = Selecting { x1 = worldPoint.x, y1 = worldPoint.y, x2 = worldPoint.x, y2 = worldPoint.y } }
                |> updateEditor Editor.clearSelection
            , Cmd.none
            )

        SelectionMove screenX screenY ->
            case model.mode of
                Selecting rect ->
                    let
                        worldPoint =
                            World.pointScreenToWorld model.editor.world { x = screenX, y = screenY }

                        updatedRect =
                            { rect | x2 = worldPoint.x, y2 = worldPoint.y }
                    in
                    ( { model | mode = Selecting updatedRect }
                        |> updateEditor (Editor.updateSelection (Selection.calculateSelection updatedRect))
                    , Cmd.none
                    )

                _ ->
                    ( model, Cmd.none )

        StopSelecting ->
            ( { model | mode = Hovering }
                |> updateEditor (Editor.updateSelection Selection.clearActiveSelection)
            , Cmd.none
            )

        ZoomMove x y delta ->
            let
                smoothedDelta =
                    delta / zoomSmoothFactor

                updatedZoomFactor =
                    model.editor.world.zoom + smoothedDelta

                correctedX =
                    x - model.editor.world.pan.x

                correctedY =
                    y - model.editor.world.pan.y

                updatedPan =
                    { x = model.editor.world.pan.x - (correctedX * smoothedDelta * 1 / model.editor.world.zoom)
                    , y = model.editor.world.pan.y - (correctedY * smoothedDelta * 1 / model.editor.world.zoom)
                    }

                updatedZoom =
                    Basics.min (Basics.max minZoomFactor updatedZoomFactor) maxZoomFactor
            in
            ( updateEditor (Editor.updateWorld (World.updatePan updatedPan >> World.updateZoom updatedZoom)) model, Cmd.none )

        StartDrawing screenX screenY ->
            let
                ( updatedEditor, nextId ) =
                    Editor.addNewDrawingWidget model.latestId { x = screenX, y = screenY } model.editor
            in
            ( { model | editor = updatedEditor, latestId = nextId, mode = Drawing model.latestId }, Cmd.none )

        DrawingMove x y ->
            case model.mode of
                Drawing widgetId ->
                    ( updateEditor (Editor.updateWidget widgetId (Widget.pushWorldPointToDrawing (World.pointScreenToWorld model.editor.world { x = x, y = y }))) model
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

        Selecting _ ->
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
        , Selection.view model.editor.world model.editor.selection
        , viewToolbar model
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
        ([ class "relative w-4 h-4 overflow-visible" ]
            ++ viewPanOffsetAndZoomStyle model
        )
        (List.map
            (\widget ->
                Widget.view
                    { widget = widget
                    , isSelected = List.member widget.id model.editor.selection.widgetsIds
                    }
            )
            model.editor.widgets
        )


viewBlueprintPattern : Editor -> Html Msg
viewBlueprintPattern editor =
    let
        backgroundPosition1 =
            String.fromFloat (-2 + editor.world.pan.x)
                ++ "px "
                ++ String.fromFloat (-2 + editor.world.pan.y)
                ++ "px"

        backgroundPosition2 =
            String.fromFloat (-1 + editor.world.pan.x)
                ++ "px "
                ++ String.fromFloat (-1 + editor.world.pan.y)
                ++ "px"

        backgroundPosition =
            style "background-position" (backgroundPosition1 ++ ", " ++ backgroundPosition1 ++ ", " ++ backgroundPosition2 ++ ", " ++ backgroundPosition2)

        backgroundSize1 =
            String.fromFloat (100 * editor.world.zoom)
                ++ "px "
                ++ String.fromFloat (100 * editor.world.zoom)
                ++ "px"

        backgroundSize2 =
            String.fromFloat (20 * editor.world.zoom)
                ++ "px "
                ++ String.fromFloat (20 * editor.world.zoom)
                ++ "px"

        backgroundSize =
            style "background-size" (backgroundSize1 ++ ", " ++ backgroundSize1 ++ ", " ++ backgroundSize2 ++ ", " ++ backgroundSize2)
    in
    div [ class "absolute top-0 left-0 w-screen h-screen blueprint-pattern", backgroundPosition, backgroundSize ] []


viewPanOffsetAndZoomStyle : Model -> List (Attribute msg)
viewPanOffsetAndZoomStyle model =
    let
        translate =
            "translate(" ++ String.fromFloat model.editor.world.pan.x ++ "px, " ++ String.fromFloat model.editor.world.pan.y ++ "px)"

        scale =
            "scale(" ++ String.fromFloat model.editor.world.zoom ++ ")"
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

                Selecting _ ->
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
