module Template.Home.Common exposing
    ( Config
    , containerAttrs
    , headingAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, Element)
import Element.Font as Font


type alias Config msg c =
    { c
        | channels : List (Element msg)
        , presence : List (Element msg)
        , socket : List (Element msg)
    }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.spacing 10
    , El.width El.fill
    ]


headingAttrs : List (Attribute msg)
headingAttrs =
    [ Font.color Color.slateblue
    , El.centerX
    ]
