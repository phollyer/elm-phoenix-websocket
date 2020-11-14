module View.Messages exposing
    ( init
    , messages
    , user
    , view
    )

import Device exposing (Device)
import Element exposing (Element)
import Template.Messages.PhonePortrait as PhonePortrait
import Types exposing (Message, User, initUser)


type Config
    = Config
        { user : User
        , messages : List Message
        }


init : Config
init =
    Config
        { user = initUser
        , messages = []
        }


view : Device -> Config -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


user : User -> Config -> Config
user user_ (Config config) =
    Config { config | user = user_ }


messages : List Message -> Config -> Config
messages list (Config config) =
    Config { config | messages = list }
