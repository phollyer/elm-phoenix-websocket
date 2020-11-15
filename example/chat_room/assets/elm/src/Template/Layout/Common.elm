module Template.Layout.Common exposing
    ( Config
    , containerAttrs
    , headerAttrs
    , homeButtonAttrs
    , titleAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, Element)
import Element.Font as Font


type alias Config msg c =
    { c
        | homeMsg : Maybe msg
        , title : String
        , body : Element msg
    }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.height El.fill
    , El.width El.fill
    , El.clip
    , El.scrollbars
    ]


headerAttrs : List (Attribute msg)
headerAttrs =
    [ El.width El.fill
    , Font.bold
    , Font.underline
    , Font.color Color.darkslateblue
    , Font.family
        [ Font.typeface "Oswald" ]
    ]


titleAttrs : List (Attribute msg)
titleAttrs =
    [ El.centerX
    , Font.bold
    , Font.underline
    , Font.color Color.darkslateblue
    , Font.family
        [ Font.typeface "Oswald" ]
    ]


homeButtonAttrs : List (Attribute msg)
homeButtonAttrs =
    [ El.mouseOver
        [ Font.color Color.aliceblue ]
    , Font.color Color.darkslateblue
    , Font.family
        [ Font.typeface "Piedra" ]
    ]
