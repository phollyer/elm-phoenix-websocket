module Page exposing
    ( Button
    , Page(..)
    , button
    , container
    , header
    , paragraph
    , view
    )

import Browser exposing (Document)
import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import Element.Input as Input
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


paragraph : List (Element msg) -> Element msg
paragraph content =
    El.paragraph
        []
        content


type alias Button a msg =
    { enabled : Bool
    , label : String
    , example : a
    , onPress : a -> msg
    , onEnter : a -> msg
    }


button : Button a msg -> Element msg
button { enabled, label, example, onPress, onEnter } =
    Input.button
        [ Background.color <|
            if enabled then
                Color.darkseagreen

            else
                Color.grey
        , Border.rounded 10
        , El.padding 10
        , El.mouseOver <|
            if enabled then
                [ Border.shadow
                    { size = 1
                    , blur = 2
                    , color = Color.seagreen
                    , offset = ( 0, 0 )
                    }
                , Font.size 31
                ]

            else
                []
        , Event.onMouseEnter <| onEnter example
        , Font.color <|
            if enabled then
                Color.darkolivegreen

            else
                Color.darkgrey
        , Font.size 30
        ]
        { label =
            El.el
                []
                (El.text label)
        , onPress =
            if enabled then
                Just (onPress example)

            else
                Nothing
        }
