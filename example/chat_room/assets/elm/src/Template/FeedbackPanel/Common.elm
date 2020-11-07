module Template.FeedbackPanel.Common exposing
    ( Config
    , containerAttrs
    , contentAttrs
    , scrollableAttrs
    , seperator
    , staticAttrs
    , titleAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font


type alias Config msg c =
    { c
        | title : String
        , static : List (Element msg)
        , scrollable : List (Element msg)
    }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ Background.color Color.white
    , Border.color Color.black
    , Border.width 1
    , El.centerX
    , El.padding 10
    , El.height <|
        El.maximum 350 El.fill
    , El.width <|
        El.maximum 500 El.fill
    ]


contentAttrs : List (Attribute msg)
contentAttrs =
    [ El.spacing 15
    , El.width El.fill
    ]


scrollableAttrs : List (Attribute msg)
scrollableAttrs =
    [ El.clip
    , El.scrollbars
    , El.height El.fill
    , El.paddingXY 0 10
    , Border.widthEach
        { left = 0
        , top = 2
        , right = 0
        , bottom = 2
        }
    , Border.color Color.skyblue
    ]


staticAttrs : List (Attribute msg)
staticAttrs =
    [ El.spacing 15
    , El.width El.fill
    , El.paddingXY 0 10
    , Border.widthEach
        { left = 0
        , top = 2
        , right = 0
        , bottom = 0
        }
    , Border.color Color.skyblue
    ]


titleAttrs : List (Attribute msg)
titleAttrs =
    [ El.centerX
    , Font.bold
    , Font.color Color.darkslateblue
    ]


seperator : Element msg
seperator =
    El.el
        [ El.width El.fill
        , Border.widthEach
            { left = 0
            , top = 0
            , right = 0
            , bottom = 1
            }
        , Border.color Color.skyblue
        ]
        El.none
