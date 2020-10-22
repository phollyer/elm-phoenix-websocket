module Session exposing
    ( Session
    , init
    , navKey
    , phoenix
    , updateDevice
    , updatePhoenix
    )

import Browser.Navigation as Nav
import Element exposing (Device)
import Phoenix
import Ports


init : Nav.Key -> Device -> Session
init key device =
    Session key device <|
        Phoenix.init Ports.config


type Session
    = Session Nav.Key Device Phoenix.Model


navKey : Session -> Nav.Key
navKey (Session key _ _) =
    key


phoenix : Session -> Phoenix.Model
phoenix (Session _ _ phx) =
    phx


updateDevice : Device -> Session -> Session
updateDevice device (Session key _ phx) =
    Session key device phx


updatePhoenix : Phoenix.Model -> Session -> Session
updatePhoenix phx (Session key device _) =
    Session key device phx
