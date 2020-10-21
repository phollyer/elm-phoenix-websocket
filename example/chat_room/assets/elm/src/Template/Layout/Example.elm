module Template.Layout.Example exposing
    ( button
    , code
    , container
    , controls
    , header
    , paragraph
    , render
    )

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input


render :
    { c
        | homeMsg : Maybe msg
        , title : String
        , introduction : List (Element msg)
        , menu : Element msg
        , example : Element msg
    }
    -> Element msg
render config =
    El.column
        [ El.height El.fill
        , El.width El.fill
        , El.spacing 20
        , El.clip
        , El.scrollbars
        , El.inFront
            (homeButton config.homeMsg)
        ]
        [ header config.title
        , introduction config.introduction
        , config.menu
        , config.example
        ]


homeButton : Maybe msg -> Element msg
homeButton msg =
    El.el
        [ El.paddingXY 0 10 ]
    <|
        Input.button
            [ El.mouseOver <|
                [ Font.color Color.aliceblue
                ]
            , Font.color Color.darkslateblue
            , Font.size 20
            ]
            { label = El.text "Home"
            , onPress = msg
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
        , El.spacing 30
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
        [ El.spacing 10 ]
        content


code : String -> Element msg
code text =
    El.el
        [ Font.family [ Font.typeface "Roboto Mono" ]
        , Background.color Color.lightgrey
        , El.padding 2
        , Border.width 1
        , Border.color Color.black
        , Font.size 16
        , Font.color Color.black
        ]
        (El.text text)


type alias Button a msg =
    { enabled : Bool
    , label : String
    , example : a
    , onPress : a -> msg
    }


button : Button a msg -> Element msg
button btn =
    let
        attrs =
            if btn.enabled then
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
            , Font.size 30
            ]
        )
        { label = El.text btn.label
        , onPress =
            if btn.enabled then
                Just (btn.onPress btn.example)

            else
                Nothing
        }
