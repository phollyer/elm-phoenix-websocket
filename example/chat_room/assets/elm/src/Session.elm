module Session exposing
    ( Session
    , init
    , navKey
    , phoenix
    , updatePhoenix
    )

import Browser.Navigation as Nav
import Phoenix
import Ports


init : Nav.Key -> Session
init key =
    Session key <|
        Phoenix.init Ports.config


type Session
    = Session Nav.Key Phoenix.Model


navKey : Session -> Nav.Key
navKey (Session key _) =
    key


phoenix : Session -> Phoenix.Model
phoenix (Session _ phx) =
    phx


updatePhoenix : Phoenix.Model -> Session -> Session
updatePhoenix phx (Session key _) =
    Session key phx
