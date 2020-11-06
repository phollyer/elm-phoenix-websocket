module Template.Layout.Common exposing
    ( Config
    , containerAttrs
    , headerAttrs
    , homeButtonAttrs
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
    , El.spacing 20
    , El.clip
    , El.scrollbars
    ]


headerAttrs : List (Attribute msg)
headerAttrs =
    [ El.paddingEach
        { left = 0
        , top = 20
        , right = 0
        , bottom = 0
        }
    , Font.center
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
