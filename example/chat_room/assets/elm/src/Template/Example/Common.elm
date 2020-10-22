module Template.Example.Common exposing
    ( containerAttrs
    , contentAttrs
    , descriptionAttrs
    , exampleIdAttrs
    , introductionAttrs
    , userIdAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute)
import Element.Font as Font


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.height El.fill
    , El.width El.fill
    , El.spacing 10
    , El.paddingEach
        { left = 0
        , top = 0
        , right = 0
        , bottom = 10
        }
    ]


contentAttrs : List (Attribute msg)
contentAttrs =
    [ El.width El.fill
    , El.spacing 20
    ]


introductionAttrs : List (Attribute msg)
introductionAttrs =
    [ Font.color Color.darkslateblue
    , Font.justify
    , Font.family
        [ Font.typeface "Piedra" ]
    ]


descriptionAttrs : List (Attribute msg)
descriptionAttrs =
    [ El.spacing 12
    , Font.color Color.darkslateblue
    , Font.justify
    , Font.family
        [ Font.typeface "Varela Round" ]
    ]


exampleIdAttrs : List (Attribute msg)
exampleIdAttrs =
    [ Font.family
        [ Font.typeface "Varela Round" ]
    ]


userIdAttrs : List (Attribute msg)
userIdAttrs =
    [ Font.family
        [ Font.typeface "Varela Round" ]
    ]
