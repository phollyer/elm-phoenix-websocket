module Page exposing
    ( Page(..)
    , view
    )

import Browser exposing (Document)
import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Attribute, DeviceClass(..), Element)
import Element.Background as Background
import Element.Border as Border


{-| Pages with content
-}
type Page
    = Home
    | ControlTheSocketConnection
    | HandleSocketMessages



{- View -}


view : Device -> { title : String, content : Element msg } -> Document msg
view device { title, content } =
    { title = title ++ " - Elm Phoenix Websocket Example"
    , body =
        [ El.layout
            [ padding device
            , Background.color Color.aliceblue
            , El.height El.fill
            , El.width El.fill
            ]
          <|
            El.el
                [ roundedBorder device
                , shadow device
                , paddingXY device
                , Background.color Color.skyblue
                , El.height El.fill
                , El.width El.fill
                , El.clip
                ]
                content
        ]
    }



{- Attributes -}


padding : Device -> Attribute msg
padding { class } =
    case class of
        Phone ->
            El.padding 10

        Tablet ->
            El.padding 20

        _ ->
            El.padding 30


paddingXY : Device -> Attribute msg
paddingXY { class } =
    case class of
        Phone ->
            El.paddingXY 10 0

        Tablet ->
            El.paddingXY 20 0

        _ ->
            El.paddingXY 30 0


roundedBorder : Device -> Attribute msg
roundedBorder { class } =
    case class of
        Phone ->
            Border.rounded 10

        Tablet ->
            Border.rounded 20

        _ ->
            Border.rounded 30


shadow : Device -> Attribute msg
shadow { class } =
    case class of
        Phone ->
            Border.shadow
                { size = 2
                , blur = 5
                , color = Color.lightblue
                , offset = ( 0, 0 )
                }

        Tablet ->
            Border.shadow
                { size = 3
                , blur = 10
                , color = Color.lightblue
                , offset = ( 0, 0 )
                }

        _ ->
            Border.shadow
                { size = 5
                , blur = 20
                , color = Color.lightblue
                , offset = ( 0, 0 )
                }
