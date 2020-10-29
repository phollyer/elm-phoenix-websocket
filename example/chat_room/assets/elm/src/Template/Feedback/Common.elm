module Template.Feedback.Common exposing
    ( Config
    , containerAttrs
    , elementAttrs
    , rowAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, DeviceClass, Element, Orientation)
import Element.Border as Border


type alias Config msg c =
    { c
        | elements : List (Element msg)
        , layout : Maybe (List Int)
    }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.paddingXY 0 10
    , El.spacing 10
    , El.width El.fill
    ]


rowAttrs : List (Attribute msg)
rowAttrs =
    [ El.spacing 10
    , El.width El.fill
    ]


elementAttrs : List (Attribute msg)
elementAttrs =
    [ El.alignTop
    , El.width El.fill
    ]
