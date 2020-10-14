module Page exposing
    ( Page(..)
    , container
    , header
    , view
    )

import Browser exposing (Document)
import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html exposing (Html)
import Phoenix


type Page
    = Home
    | Other
    | ControlTheSocketConnection


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
            (El.el
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
                , El.padding 20
                ]
                content
            )
        ]
    }


container : List (Element msg) -> Element msg
container content =
    El.column
        [ El.height El.fill
        , El.width El.fill
        , El.spacing 20
        ]
        content


header : String -> Element msg
header title =
    El.el
        [ El.centerX
        , Font.color Color.darkslateblue
        , Font.size 40
        ]
        (El.text title)
