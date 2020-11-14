module View.Example exposing
    ( Config, init
    , view
    , id, description, controls, feedback
    )

{-| This module is intended to enable building up an example with pipelines and
then passing off the example config to the chosen template - currently there is
only one.

@docs Config, init

@docs Template, view

@docs id, introduction, menu, description, controls, remoteControls, feedback, info

-}

import Device exposing (Device)
import Element as El exposing (DeviceClass(..), Element, Orientation(..))
import Template.Example.PhoneLandscape as PhoneLandscape
import Template.Example.PhonePortrait as PhonePortrait
import Template.Example.Tablet as Tablet


{-| -}
type Config msg
    = Config
        { id : Maybe String
        , description : List (List (Element msg))
        , controls : Element msg
        , feedback : Element msg
        }


{-| -}
init : Config msg
init =
    Config
        { id = Nothing
        , description = []
        , controls = El.none
        , feedback = El.none
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
controls : Element msg -> Config msg -> Config msg
controls cntrls (Config config) =
    Config { config | controls = cntrls }


{-| -}
description : List (List (Element msg)) -> Config msg -> Config msg
description desc (Config config) =
    Config { config | description = desc }


{-| -}
feedback : Element msg -> Config msg -> Config msg
feedback feedback_ (Config config) =
    Config { config | feedback = feedback_ }


{-| -}
id : Maybe String -> Config msg -> Config msg
id maybeId (Config config) =
    Config { config | id = maybeId }
