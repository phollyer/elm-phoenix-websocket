module View.Layout exposing
    ( Config
    , body
    , homeMsg
    , init
    , title
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Attribute, DeviceClass(..), Element, Orientation(..))
import Element.Font as Font
import Element.Input as Input



{- Model -}


type Config msg
    = Config
        { homeMsg : Maybe msg
        , title : String
        , body : Element msg
        }


init : Config msg
init =
    Config
        { homeMsg = Nothing
        , title = ""
        , body = El.none
        }


homeMsg : Maybe msg -> Config msg -> Config msg
homeMsg msg (Config config) =
    Config { config | homeMsg = msg }


title : String -> Config msg -> Config msg
title text (Config config) =
    Config { config | title = text }


body : Element msg -> Config msg -> Config msg
body body_ (Config config) =
    Config { config | body = body_ }



{- View -}


view : Device -> Config msg -> Element msg
view device (Config config) =
    El.column
        [ El.inFront (homeButton device config.homeMsg)
        , El.height El.fill
        , El.width El.fill
        , El.clip
        , El.scrollbars
        ]
        [ header device config.title
        , config.body
        ]


header : Device -> String -> Element msg
header device text =
    El.row
        [ fontSize device
        , El.width El.fill
        , Font.bold
        , Font.underline
        , Font.color Color.darkslateblue
        , Font.family
            [ Font.typeface "Oswald" ]
        ]
        [ El.el
            [ padding device
            , El.centerX
            , Font.bold
            , Font.underline
            , Font.color Color.darkslateblue
            , Font.family
                [ Font.typeface "Oswald" ]
            ]
            (El.text text)
        ]


homeButton : Device -> Maybe msg -> Element msg
homeButton device maybeMsg =
    case maybeMsg of
        Nothing ->
            El.none

        Just msg ->
            El.el
                [ padding device ]
            <|
                Input.button
                    [ fontSize device
                    , El.mouseOver
                        [ Font.color Color.aliceblue ]
                    , Font.color Color.darkslateblue
                    , Font.family
                        [ Font.typeface "Piedra" ]
                    ]
                    { label = El.text "<="
                    , onPress = Just msg
                    }



{- Attributes -}


fontSize : Device -> Attribute msg
fontSize { class } =
    case class of
        Phone ->
            Font.size 20

        _ ->
            Font.size 40


padding : Device -> Attribute msg
padding { class } =
    case class of
        Phone ->
            El.paddingXY 0 5

        _ ->
            El.paddingXY 0 10
