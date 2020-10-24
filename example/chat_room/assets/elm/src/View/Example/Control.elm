module View.Example.Control exposing
    ( Config
    , enabled
    , example
    , id
    , init
    , label
    , onPress
    , view
    )

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.Example.Controls.Control.PhonePortrait as PhonePortrait


type Config example msg
    = Config
        { id : String
        , enabled : Bool
        , label : String
        , example : Maybe example
        , onPress : Maybe (example -> msg)
        }


init : Config example msg
init =
    Config
        { id = ""
        , enabled = False
        , label = ""
        , example = Nothing
        , onPress = Nothing
        }


view : Device -> Config a msg -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


id : String -> Config e m -> Config e m
id id_ (Config config) =
    Config { config | id = id_ }


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
