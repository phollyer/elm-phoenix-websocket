module Template.Layout.Home exposing (render)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Font as Font


render : { c | title : String, column : List (Element msg) } -> Element msg
render config =
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
