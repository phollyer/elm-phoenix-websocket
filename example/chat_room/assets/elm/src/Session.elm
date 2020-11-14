module Session exposing
    ( Session
    , device
    , init
    , navKey
    , phoenix
    , updateDevice
    , updatePhoenix
    )

import Browser.Navigation as Nav
import Device exposing (Device)
import Phoenix
import Ports


init : Nav.Key -> Device -> Session
init key device_ =
    Session key device_ <|
        Phoenix.init Ports.config


type Session
    = Session Nav.Key Device Phoenix.Model


navKey : Session -> Nav.Key
navKey (Session key _ _) =
    key


phoenix : Session -> Phoenix.Model
phoenix (Session _ _ phx) =
    phx


device : Session -> Device
device (Session _ device_ _) =
    device_


updateDevice : Device -> Session -> Session
updateDevice device_ (Session key _ phx) =
    Session key device_ phx


updatePhoenix : Phoenix.Model -> Session -> Session
updatePhoenix phx (Session key device_ _) =
    Session key device_ phx
