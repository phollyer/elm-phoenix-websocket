module View.LobbyRoom exposing
    ( init
    , onClick
    , room
    , view
    )

import Device exposing (Device)
import Element exposing (Element)
import Template.LobbyRoom.PhonePortrait as PhonePortrait
import Types exposing (Room, User)


type Config msg
    = Config
        { room : Room
        , onClick : Maybe (Room -> msg)
        }


init : Config msg
init =
    Config
        { room = Room "" (User "" "") [] []
        , onClick = Nothing
        }


view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


room : Room -> Config msg -> Config msg
room room_ (Config config) =
    Config { config | room = room_ }


onClick : (Room -> msg) -> Config msg -> Config msg
onClick toMsg (Config config) =
    Config { config | onClick = Just toMsg }
