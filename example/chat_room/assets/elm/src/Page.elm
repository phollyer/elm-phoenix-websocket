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


view : Phoenix.Model -> Page -> { title : String, content : Element msg } -> Document msg
view phoenix page { title, content } =
    { title = title ++ " - Elm Phoenix Websocket Example"
    , body =
        [ El.layout
            [ Background.color Color.aliceblue
            , El.height El.fill
            , El.width El.fill
            , El.padding 40
            ]
          <|
            El.el
                [ Background.color Color.skyblue
                , Border.rounded 20
                , Border.shadow
                    { size = 3
                    , blur = 10
                    , color = Color.lightblue
                    , offset = ( 0, 0 )
                    }
                , El.height El.fill
                , El.width El.fill
                , El.paddingXY 20 0
                ]
                content
        ]
    }
