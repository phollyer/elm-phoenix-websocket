module View.Home exposing
    ( Config
    , Template(..)
    , channels
    , init
    , presence
    , render
    , socket
    )

import Element exposing (Element)
import Template.Home.Default as Default


type Config msg
    = Config
        { channels : List (Element msg)
        , presence : List (Element msg)
        , socket : List (Element msg)
        }


init : Config msg
init =
    Config
        { channels = []
        , presence = []
        , socket = []
        }


type Template
    = Default


render : Template -> Config msg -> Element msg
render template (Config config) =
    case template of
        Default ->
            Default.render config


channels : List (Element msg) -> Config msg -> Config msg
channels channels_ (Config config) =
    Config
        { config | channels = channels_ }


presence : List (Element msg) -> Config msg -> Config msg
presence presence_ (Config config) =
    Config
        { config | presence = presence_ }


socket : List (Element msg) -> Config msg -> Config msg
socket socket_ (Config config) =
    Config
        { config | socket = socket_ }
