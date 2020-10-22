module Page exposing
    ( Page(..)
    , view
    )

import Browser exposing (Document)
import Colors.Opaque as Color
import Element as El exposing (Attribute, Device, DeviceClass(..), Element, Orientation(..))
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
            [ Background.color Color.aliceblue
            , El.height El.fill
            , El.width El.fill
            , padding device
            ]
          <|
            El.el
                [ Background.color Color.skyblue
                , Border.rounded 20
                , Border.shadow
                    { size = 3
                    , blur = 10
                    , color = Color.lightblue
                    , offset = ( 0, 0 )
                    }
                , El.height El.fill
                , El.width El.fill
                , El.paddingXY 10 0
                , El.clip
                ]
                content
        ]
    }


padding : Device -> Attribute msg
padding { class } =
    case class of
        Phone ->
            El.padding 10

        Tablet ->
            El.padding 20

        _ ->
            El.padding 40
