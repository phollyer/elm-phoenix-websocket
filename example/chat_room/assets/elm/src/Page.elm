module Page exposing
    ( Button
    , Page(..)
    , button
    , container
    , controls
    , header
    , introduction
    , menu
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
                , El.paddingXY 20 0
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
        , El.clip
        , El.scrollbars
        ]
        content


header : String -> Element msg
header title =
    El.el
        [ El.centerX
        , El.paddingEach
            { left = 0
            , top = 20
            , right = 0
            , bottom = 0
            }
        , Font.bold
        , Font.underline
        , Font.color Color.darkslateblue
        , Font.size 40
        , Font.family
            [ Font.typeface "Oswald" ]
        ]
        (El.text title)


introduction : List (Element msg) -> Element msg
introduction intro =
    El.column
        [ Font.color Color.darkslateblue
        , Font.size 24
        , Font.justify
        , El.spacing 20
        , Font.family
            [ Font.typeface "Piedra" ]
        ]
        intro


controls : List (Element msg) -> Element msg
controls cntrls =
    El.wrappedRow
        [ El.centerX
        , El.spacing 20
        ]
        cntrls


paragraph : List (Element msg) -> Element msg
paragraph content =
    El.paragraph
        []
        content


menu : List ( String, msg ) -> String -> Element msg
menu items selected =
    El.el
        [ Border.widthEach
            { left = 0
            , top = 1
            , right = 0
            , bottom = 1
            }
        , Border.color Color.aliceblue
        , El.paddingEach
            { left = 5
            , top = 10
            , right = 5
            , bottom = 0
            }
        , El.width El.fill
        , Font.family
            [ Font.typeface "Varela Round" ]
        ]
        (El.wrappedRow
            [ El.centerX
            , El.spacing 20
            ]
            (List.map (menuItem selected) items)
        )


menuItem : String -> ( String, msg ) -> Element msg
menuItem selected ( item, msg ) =
    let
        ( attrs, highlight ) =
            if selected == item then
                ( [ Font.color Color.darkslateblue
                  , El.spacing 5
                  ]
                , El.el
                    [ Border.width 2
                    , Border.color Color.aliceblue
                    , El.width El.fill
                    ]
                    El.none
                )

            else
                ( [ Font.color Color.darkslateblue
                  , El.paddingEach
                        { left = 0
                        , top = 0
                        , right = 0
                        , bottom = 5
                        }
                  , Border.widthEach
                        { left = 0
                        , top = 0
                        , right = 0
                        , bottom = 4
                        }
                  , Border.color Color.skyblue
                  , El.pointer
                  , Event.onClick msg
                  , El.mouseOver
                        [ Border.color Color.lavender ]
                  ]
                , El.none
                )
    in
    El.column
        attrs
        [ El.text item
        , highlight
        ]


type alias Button a msg =
    { enabled : Bool
    , label : String
    , example : a
    , onPress : a -> msg
    , onEnter : a -> msg
    }


button : Button a msg -> Element msg
button { enabled, label, example, onPress, onEnter } =
    let
        attrs =
            if enabled then
                [ Background.color Color.darkseagreen
                , El.mouseOver <|
                    [ Border.shadow
                        { size = 1
                        , blur = 2
                        , color = Color.seagreen
                        , offset = ( 0, 0 )
                        }
                    , Font.size 31
                    ]
                , Font.color Color.darkolivegreen
                ]

            else
                [ Background.color Color.grey
                , Font.color Color.darkgrey
                ]
    in
    Input.button
        (List.append
            attrs
            [ Border.rounded 10
            , El.padding 10
            , Event.onMouseEnter <| onEnter example
            , Font.size 30
            ]
        )
        { label = El.text label
        , onPress =
            if enabled then
                Just (onPress example)

            else
                Nothing
        }
