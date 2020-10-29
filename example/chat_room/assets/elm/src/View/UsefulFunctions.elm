module View.UsefulFunctions exposing
    ( functions
    , init
    , view
    )

import Element exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.UsefulFunctions.PhoneLandscape as PhoneLandscape
import Template.UsefulFunctions.PhonePortrait as PhonePortrait
import Template.UsefulFunctions.Tablet as Tablet


type Config
    = Config { functions : List ( String, String ) }


init : Config
init =
    Config { functions = [] }


view : Device -> Config -> Element msg
view { class, orientation } (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.view config

        ( Phone, Landscape ) ->
            PhoneLandscape.view config

        _ ->
            Tablet.view config


functions : List ( String, String ) -> Config -> Config
functions functions_ (Config config) =
    Config { config | functions = functions_ }
