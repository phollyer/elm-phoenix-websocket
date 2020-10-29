module View.ApplicableFunctions exposing
    ( functions
    , init
    , view
    )

import Element exposing (Device, DeviceClass(..), Element, Orientation)
import Template.ApplicableFunctions.PhoneLandscape as PhoneLandscape
import Template.ApplicableFunctions.PhonePortrait as PhonePortrait


type Config
    = Config { functions : List String }


init : Config
init =
    Config { functions = [] }


view : Device -> Config -> Element msg
view { class, orientation } (Config config) =
    case ( class, orientation ) of
        ( Phone, _ ) ->
            PhonePortrait.view config

        _ ->
            PhoneLandscape.view config


functions : List String -> Config -> Config
functions functions_ (Config config) =
    Config { config | functions = functions_ }
