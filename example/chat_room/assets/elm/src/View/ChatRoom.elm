module View.ChatRoom exposing
    ( init
    , introduction
    , messageForm
    , room
    , view
    )

import Element as El exposing (Device, Element)
import Template.ChatRoom.PhonePortrait as PhonePortrait
import Types exposing (Room, initRoom)


type Config msg
    = Config
        { room : Room
        , introduction : List (List (Element msg))
        , messageForm : Element msg
        }


init : Config msg
init =
    Config
        { room = initRoom
        , introduction = []
        , messageForm = El.none
        }


view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


introduction : List (List (Element msg)) -> Config msg -> Config msg
introduction intro (Config config) =
    Config { config | introduction = intro }


room : Room -> Config msg -> Config msg
room room_ (Config config) =
    Config { config | room = room_ }


messageForm : Element msg -> Config msg -> Config msg
messageForm form (Config config) =
    Config { config | messageForm = form }
