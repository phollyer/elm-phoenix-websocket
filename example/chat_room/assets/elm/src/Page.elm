module Page exposing
    ( Page(..)
    , view
    )

import Browser exposing (Document)
import Device exposing (Device)
import Element exposing (Element)
import View.Page as Page


{-| Pages with content
-}
type Page
    = Home
    | ControlTheSocketConnection
    | HandleSocketMessages



{- View -}


view : Device -> { title : String, content : Element msg } -> Document msg
view device { title, content } =
    { title = title ++ " - Elm Phoenix Websocket Example"
    , body =
        [ Page.init
            |> Page.body content
            |> Page.view device
        ]
    }
