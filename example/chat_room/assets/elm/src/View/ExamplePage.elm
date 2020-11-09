module View.ExamplePage exposing
    ( Config, init
    , view
    , id, introduction, menu, example
    )

{-| This module is intended to enable building up an example with pipelines and
then passing off the example config to the chosen template - currently there is
only one.

@docs Config, init

@docs Template, view

@docs id, introduction, menu, example

-}

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.ExamplePage.PhoneLandscape as PhoneLandscape
import Template.ExamplePage.PhonePortrait as PhonePortrait
import Template.ExamplePage.Tablet as Tablet


{-| -}
type Config msg
    = Config
        { id : Maybe String
        , introduction : List (List (Element msg))
        , menu : Element msg
        , example : Element msg
        }


{-| -}
init : Config msg
init =
    Config
        { id = Nothing
        , introduction = []
        , menu = El.none
        , example = El.none
        }


{-| -}
view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.view config

        ( Phone, Landscape ) ->
            PhoneLandscape.view config

        _ ->
            Tablet.view config


{-| -}
id : Maybe String -> Config msg -> Config msg
id maybeId (Config config) =
    Config { config | id = maybeId }


{-| -}
introduction : List (List (Element msg)) -> Config msg -> Config msg
introduction list (Config config) =
    Config { config | introduction = list }


{-| -}
menu : Element msg -> Config msg -> Config msg
menu menu_ (Config config) =
    Config { config | menu = menu_ }


{-| -}
example : Element msg -> Config msg -> Config msg
example desc (Config config) =
    Config { config | example = desc }
