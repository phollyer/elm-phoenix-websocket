module View.Home.Panel exposing
    ( Config
    , description
    , init
    , onClick
    , title
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font
import View exposing (andMaybeEventWith)



{- Model -}


type Config msg
    = Config
        { title : String
        , description : List String
        , onClick : Maybe msg
        }


init : Config msg
init =
    Config
        { title = ""
        , description = []
        , onClick = Nothing
        }


title : String -> Config msg -> Config msg
title text (Config config) =
    Config { config | title = text }


description : List String -> Config msg -> Config msg
description desc (Config config) =
    Config { config | description = desc }


onClick : Maybe msg -> Config msg -> Config msg
onClick maybeMsg (Config config) =
    Config { config | onClick = maybeMsg }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    panel config.onClick
        [ header device config.title
        , content device config.description
        ]



{- Panel -}


panel : Maybe msg -> List (Element msg) -> Element msg
panel maybeMsg =
    El.column
        (panelAttrs
            |> andMaybeEventWith maybeMsg Event.onClick
        )


panelAttrs : List (Attribute msg)
panelAttrs =
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
    , El.height <|
        El.maximum 300 El.fill
    , El.width <| El.maximum 250 El.fill
    , El.centerX
    ]



{- Header -}


header : Device -> String -> Element msg
header device text =
    El.el
        (headerAttrs device)
        (El.paragraph
            [ El.width El.fill
            , Font.center
            ]
            [ El.text text ]
        )


headerAttrs : Device -> List (Attribute msg)
headerAttrs { class } =
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
    , Font.size <|
        case class of
            Phone ->
                16

            _ ->
                20
    ]



{- Content -}


content : Device -> List String -> Element msg
content device paragraphs =
    El.column
        [ Background.color Color.lightskyblue
        , El.padding 10
        , El.spacing 10
        , El.height El.fill
        , El.width El.fill
        ]
        (List.map (toParagraph device) paragraphs)


toParagraph : Device -> String -> Element msg
toParagraph device paragraph =
    El.paragraph
        (paragraphAttrs device)
        [ El.text paragraph ]


paragraphAttrs : Device -> List (Attribute msg)
paragraphAttrs { class } =
    [ El.width El.fill
    , Font.justify
    , Font.size <|
        case class of
            Phone ->
                12

            _ ->
                18
    ]
