module Template.Layout.App exposing
    ( container
    , controls
    , header
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
        , body : Element msg
    }
    -> Element msg
render { homeMsg, title, body } =
    El.column
        [ El.height El.fill
        , El.width El.fill
        , El.spacing 20
        , El.clip
        , El.scrollbars
        , El.inFront
            (homeButton homeMsg)
        ]
        [ header title
        , body
        ]


homeButton : Maybe msg -> Element msg
homeButton maybeMsg =
    case maybeMsg of
        Nothing ->
            El.none

        Just msg ->
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
                    , onPress = Just msg
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