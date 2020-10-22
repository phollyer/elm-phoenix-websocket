module Template.Layout.PhonePortrait exposing (render)

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
                [ El.paddingXY 0 10
                , Font.family
                    [ Font.typeface "Piedra" ]
                ]
            <|
                Input.button
                    [ El.mouseOver <|
                        [ Font.color Color.aliceblue
                        ]
                    , Font.color Color.darkslateblue
                    , Font.size 20
                    ]
                    { label = El.text "<="
                    , onPress = Just msg
                    }


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
        , Font.size 24
        , Font.family
            [ Font.typeface "Oswald" ]
        ]
        (El.text title)
