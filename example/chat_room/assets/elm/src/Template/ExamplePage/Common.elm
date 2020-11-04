module Template.ExamplePage.Common exposing
    ( Config
    , containerAttrs
    , exampleAttrs
    , idAttrs
    , idLabelAttrs
    , idValueAttrs
    , introductionAttrs
    , menuAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass, Element, Orientation)
import Element.Font as Font


type alias Config msg c =
    { c
        | id : Maybe String
        , introduction : List (Element msg)
        , menu : Element msg
        , example : Element msg
    }


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


introductionAttrs : List (Attribute msg)
introductionAttrs =
    [ Font.color Color.darkslateblue
    , Font.justify
    , Font.family
        [ Font.typeface "Piedra" ]
    ]


menuAttrs : List (Attribute msg)
menuAttrs =
    [ El.width El.fill ]


exampleAttrs : List (Attribute msg)
exampleAttrs =
    [ El.spacing 12
    , Font.color Color.darkslateblue
    , Font.justify
    , Font.family
        [ Font.typeface "Varela Round" ]
    , El.width El.fill
    ]


idAttrs : List (Attribute msg)
idAttrs =
    [ Font.center
    , Font.family
        [ Font.typeface "Varela Round" ]
    ]


idLabelAttrs : List (Attribute msg)
idLabelAttrs =
    [ Font.color Color.lavender ]


idValueAttrs : List (Attribute msg)
idValueAttrs =
    [ Font.color Color.powderblue ]
