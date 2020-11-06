module Template.Feedback.Common exposing
    ( Config
    , containerAttrs
    , elementAttrs
    , rowAttrs
    )

import Element as El exposing (Attribute, Element)


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
