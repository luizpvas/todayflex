module Tool exposing (Tool(..), toolFromShortcut, toolToShortcut)


type Tool
    = Move
    | Pencil


toolFromShortcut : String -> Maybe Tool
toolFromShortcut key =
    case key of
        "v" ->
            Just Move

        "p" ->
            Just Pencil

        _ ->
            Nothing


toolToShortcut : Tool -> String
toolToShortcut tool =
    case tool of
        Move ->
            "V"

        Pencil ->
            "P"
