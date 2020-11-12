module View.LobbyRoom exposing
    ( init
    , room
    , view
    )

import Element exposing (Device, Element)
import Template.LobbyRoom.PhonePortrait as PhonePortrait
import Types exposing (Room, User)


type Config
    = Config Room


init : Config
init =
    Config (Room "" (User "" "") [] [])


view : Device -> Config -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view { room = config }


room : Room -> Config -> Config
room room_ _ =
    Config room_
