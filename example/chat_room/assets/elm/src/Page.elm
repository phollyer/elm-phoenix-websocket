module Page exposing
    ( Page(..)
    , view
    )

import Browser exposing (Document)
import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border


type Page
    = Home
    | ControlTheSocketConnection
    | HandleSocketMessages


view : { title : String, content : Element msg } -> Document msg
view { title, content } =
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
