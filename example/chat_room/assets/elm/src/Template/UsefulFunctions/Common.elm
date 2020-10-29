module Template.UsefulFunctions.Common exposing
    ( Config
    , containerAttrs
    , contentAttrs
    , headingAttrs
    , rowAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute)
import Element.Font as Font


type alias Config =
    { functions : List ( String, String ) }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.width El.fill ]


contentAttrs : List (Attribute msg)
contentAttrs =
    [ El.width El.fill ]


headingAttrs : List (Attribute msg)
headingAttrs =
    [ Font.bold
    , Font.color Color.darkslateblue
    , El.width El.fill
    ]


rowAttrs : List (Attribute msg)
rowAttrs =
    [ El.width El.fill ]
