module View.ChatRoom exposing
    ( init
    , introduction
    , membersTyping
    , messageForm
    , messages
    , view
    )

import Element as El exposing (Device, Element)
import Template.ChatRoom.PhonePortrait as PhonePortrait


type Config msg
    = Config
        { introduction : List (List (Element msg))
        , messageForm : Element msg
        , membersTyping : List String
        , messages : Element msg
        }


init : Config msg
init =
    Config
        { introduction = []
        , messageForm = El.none
        , membersTyping = []
        , messages = El.none
        }


view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


introduction : List (List (Element msg)) -> Config msg -> Config msg
introduction intro (Config config) =
    Config { config | introduction = intro }


messageForm : Element msg -> Config msg -> Config msg
messageForm form (Config config) =
    Config { config | messageForm = form }


membersTyping : List String -> Config msg -> Config msg
membersTyping members (Config config) =
    Config { config | membersTyping = members }


messages : Element msg -> Config msg -> Config msg
messages element (Config config) =
    Config { config | messages = element }
