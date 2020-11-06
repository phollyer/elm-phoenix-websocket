module Template.Example.Common exposing
    ( Config
    , containerAttrs
    , controlsAttrs
    , descriptionAttrs
    , idAttrs
    , idLabelAttrs
    , idValueAttrs
    , introductionAttrs
    , menuAttrs
    , remoteControlAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, Element)
import Element.Font as Font


type alias Config msg c =
    { c
        | id : Maybe String
        , introduction : List (Element msg)
        , menu : Element msg
        , description : List (Element msg)
        , controls : Element msg
        , remoteControls : List (Element msg)
        , feedback : Element msg
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


descriptionAttrs : List (Attribute msg)
descriptionAttrs =
    [ El.spacing 12
    , Font.color Color.darkslateblue
    , Font.justify
    , Font.family
        [ Font.typeface "Varela Round" ]
    , El.width El.fill
    ]


controlsAttrs : List (Attribute msg)
controlsAttrs =
    [ El.width El.fill ]


remoteControlAttrs : List (Attribute msg)
remoteControlAttrs =
    [ El.width El.fill ]


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
