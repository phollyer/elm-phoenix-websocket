module Template.Layout.Blank exposing (render)

import Colors.Opaque as Color
import Element as El
import Element.Background as Background
import Element.Border as Border
import Html exposing (Html)


render : Html msg
render =
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
            El.none
