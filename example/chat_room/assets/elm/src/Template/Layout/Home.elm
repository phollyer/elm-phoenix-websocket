module Template.Layout.Home exposing (render)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Html exposing (Html)


render : { c | title : String, column : List (Element msg) } -> Html msg
render config =
    El.layout
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
        <|
            El.column
                [ El.height El.fill
                , El.width El.fill
                , El.spacing 20
                , El.clip
                , El.scrollbars
                ]
            <|
                header config.title
                    :: config.column


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
