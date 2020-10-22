module Template.Home.Common exposing
    ( containerAttrs
    , headingAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute)
import Element.Font as Font


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
