module View.UsefulFunctions exposing
    ( functions
    , init
    , view
    )

import Element exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.UsefulFunctions.PhonePortrait as PhonePortrait
import Template.UsefulFunctions.Tablet as Tablet


type Config
    = Config (List ( String, String ))


init : Config
init =
    Config []


view : Device -> Config -> Element msg
view { class, orientation } (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            PhonePortrait.view config

        _ ->
            Tablet.view config


functions : List ( String, String ) -> Config -> Config
functions functions_ (Config _) =
    Config functions_
