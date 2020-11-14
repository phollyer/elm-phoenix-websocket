module Template.ChatRoom.Common exposing
    ( Config
    , containerAttrs
    , contentAttrs
    , messagesAttrs
    )

import Colors.Opaque as Color
import Element as El exposing (Attribute, Element)
import Element.Background as Background
import Element.Border as Border
import Html.Attributes as Attr


type alias Config msg c =
    { c
        | introduction : List (List (Element msg))
        , messageForm : Element msg
        , membersTyping : List String
        , messages : Element msg
    }


containerAttrs : List (Attribute msg)
containerAttrs =
    [ El.spacing 10
    , El.height El.fill
    , El.width El.fill
    ]


contentAttrs : Int -> List (Attribute msg)
contentAttrs maxHeight =
    [ El.alignBottom
    , El.spacing 10
    , El.width El.fill
    , El.height <|
        El.maximum maxHeight El.fill
    ]


messagesAttrs : List (Attribute msg)
messagesAttrs =
    [ Background.color Color.white
    , Border.rounded 10
    , El.htmlAttribute <|
        Attr.id "message-list"
    , El.height El.fill
    , El.width El.fill
    , El.clipY
    , El.scrollbarY
    ]
