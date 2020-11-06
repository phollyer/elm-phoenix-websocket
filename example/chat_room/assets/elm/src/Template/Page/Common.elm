module Template.Page.Common exposing
    ( bodyAttrs
    , layoutAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute)
import Element.Background as Background


layoutAttrs : List (Attribute msg)
layoutAttrs =
    [ Background.color Color.aliceblue
    , El.height El.fill
    , El.width El.fill
    ]


bodyAttrs : List (Attribute msg)
bodyAttrs =
    [ Background.color Color.skyblue
    , El.height El.fill
    , El.width El.fill
    , El.clip
    ]
