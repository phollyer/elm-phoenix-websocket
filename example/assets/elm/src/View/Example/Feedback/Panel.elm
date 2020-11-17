module View.Example.Feedback.Panel exposing
    ( Config
    , init
    , scrollable
    , static
    , title
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font



{- Model -}


type Config msg
    = Config
        { title : String
        , static : List (Element msg)
        , scrollable : List (Element msg)
        }


init : Config msg
init =
    Config
        { title = ""
        , static = []
        , scrollable = []
        }


title : String -> Config msg -> Config msg
title title_ (Config config) =
    Config { config | title = title_ }


scrollable : List (Element msg) -> Config msg -> Config msg
scrollable scrollable_ (Config config) =
    Config { config | scrollable = scrollable_ }


static : List (Element msg) -> Config msg -> Config msg
static static_ (Config config) =
    Config { config | static = static_ }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    El.column
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
        [ titleView device config.title
        , staticView config.static
        , scrollableView config.scrollable
        ]


titleView : Device -> String -> Element msg
titleView device title_ =
    El.el
        [ fontSize device
        , El.centerX
        , Font.bold
        , Font.color Color.darkslateblue
        ]
        (El.text title_)


staticView : List (Element msg) -> Element msg
staticView elements =
    case elements of
        [] ->
            El.none

        _ ->
            El.column
                (List.append
                    contentAttrs
                    [ Border.widthEach
                        { left = 0
                        , top = 2
                        , right = 0
                        , bottom = 0
                        }
                    ]
                )
                elements


scrollableView : List (Element msg) -> Element msg
scrollableView elements =
    case elements of
        [] ->
            El.none

        _ ->
            El.column
                (List.append
                    contentAttrs
                    [ El.clipY
                    , El.scrollbarY
                    , El.height El.fill
                    , Border.widthEach
                        { left = 0
                        , top = 2
                        , right = 0
                        , bottom = 2
                        }
                    ]
                )
                (elements
                    |> List.intersperse seperator
                )


seperator : Element msg
seperator =
    El.el
        [ Border.widthEach
            { left = 0
            , top = 0
            , right = 0
            , bottom = 1
            }
        , Border.color Color.skyblue
        , El.width El.fill
        ]
        El.none



{- Attributes -}


contentAttrs : List (Attribute msg)
contentAttrs =
    [ Border.color Color.skyblue
    , El.spacing 15
    , El.paddingXY 0 10
    , El.width El.fill
    ]


fontSize : Device -> Attribute msg
fontSize { class } =
    case class of
        Phone ->
            Font.size 16

        Tablet ->
            Font.size 20

        _ ->
            Font.size 22
