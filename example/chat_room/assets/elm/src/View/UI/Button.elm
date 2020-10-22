module View.UI.Button exposing
    ( Config
    , enabled
    , example
    , init
    , label
    , onPress
    , render
    )

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.UI.Button.Default as Default


type Config example msg
    = Config
        { enabled : Bool
        , label : String
        , example : Maybe example
        , onPress : Maybe (example -> msg)
        }


init : Config example msg
init =
    Config
        { enabled = False
        , label = ""
        , example = Nothing
        , onPress = Nothing
        }


render : Device -> Config a msg -> Element msg
render { class, orientation } (Config config) =
    case ( class, orientation ) of
        _ ->
            Default.render config


enabled : Bool -> Config e m -> Config e m
enabled enabled_ (Config config) =
    Config { config | enabled = enabled_ }


label : String -> Config e m -> Config e m
label label_ (Config config) =
    Config { config | label = label_ }


example : Maybe e -> Config e m -> Config e m
example maybeExample (Config config) =
    Config { config | example = maybeExample }


onPress : Maybe (e -> m) -> Config e m -> Config e m
onPress maybeMsg (Config config) =
    Config { config | onPress = maybeMsg }
