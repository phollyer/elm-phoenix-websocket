module View.LobbyRooms exposing
    ( elements
    , init
    , view
    )

import Device exposing (Device)
import Element exposing (Element)
import Template.LobbyRooms.PhonePortrait as PhonePortrait


type Config msg
    = Config (List (Element msg))


init : Config msg
init =
    Config []


view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view { elements = config }


elements : List (Element msg) -> Config msg -> Config msg
elements elements_ _ =
    Config elements_
