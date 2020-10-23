module Page exposing
    ( Page(..)
    , view
    )

import Browser exposing (Document)
import Colors.Opaque as Color
import Element as El exposing (Attribute, Device, DeviceClass(..), Element, Orientation(..))
import Element.Background as Background
import Element.Border as Border
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
