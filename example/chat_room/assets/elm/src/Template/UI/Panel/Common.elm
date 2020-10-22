module Template.UI.Panel.Common exposing
    ( containerAttrs
    , contentAttrs
    , descriptionAttrs
    , headerAttrs
    , onClick
    , titleAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font


onClick : Maybe msg -> List (Attribute msg)
onClick maybeMsg =
    case maybeMsg of
        Nothing ->
            []

        Just msg ->
            [ Event.onClick msg ]


containerAttrs : List (Attribute msg)
containerAttrs =
    [ Background.color Color.steelblue
    , Border.rounded 20
    , Border.width 1
    , Border.color Color.steelblue
    , El.clip
    , El.pointer
    , El.mouseOver
        [ Border.shadow
            { size = 2
            , blur = 3
            , color = Color.steelblue
            , offset = ( 0, 0 )
            }
        ]
    ]


headerAttrs : List (Attribute msg)
headerAttrs =
    [ Background.color Color.steelblue
    , Border.roundEach
        { topLeft = 20
        , topRight = 20
        , bottomRight = 0
        , bottomLeft = 0
        }
    , El.paddingXY 5 10
    , El.width El.fill
    , Font.color Color.aliceblue
    ]


titleAttrs : List (Attribute msg)
titleAttrs =
    [ El.width El.fill
    , Font.center
    ]


contentAttrs : List (Attribute msg)
contentAttrs =
    [ Background.color Color.lightskyblue
    , El.height El.fill
    , El.width El.fill
    , El.padding 10
    , El.spacing 10
    ]


descriptionAttrs : List (Attribute msg)
descriptionAttrs =
    [ El.width El.fill
    , Font.justify
    ]
