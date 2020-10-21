module Page exposing
    ( Page(..)
    , view
    )

import Browser exposing (Document)
import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Html exposing (Html)
import Phoenix


type Page
    = Home
    | Other
    | ControlTheSocketConnection
    | HandleSocketMessages


view : Phoenix.Model -> Page -> { title : String, content : Html msg } -> Document msg
view phoenix page { title, content } =
    { title = title ++ " - Elm Phoenix Websocket Example"
    , body = [ content ]
    }
