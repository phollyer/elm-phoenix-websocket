module View.ApplicableFunctions exposing
    ( functions
    , init
    , view
    )

import Device exposing (Device)
import Element exposing (DeviceClass(..), Element)
import Template.ApplicableFunctions.PhoneLandscape as PhoneLandscape
import Template.ApplicableFunctions.PhonePortrait as PhonePortrait


type Config
    = Config (List String)


init : Config
init =
    Config []


view : Device -> Config -> Element msg
view { class, orientation } (Config config) =
    case ( class, orientation ) of
        ( Phone, _ ) ->
            PhonePortrait.view config

        _ ->
            PhoneLandscape.view config


functions : List String -> Config -> Config
functions functions_ (Config _) =
    Config functions_
