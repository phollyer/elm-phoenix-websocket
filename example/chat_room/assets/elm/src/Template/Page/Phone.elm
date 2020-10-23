module Template.Page.Phone exposing (..)

import Colors.Opaque as Color
import Element as El exposing (Attribute, Device, DeviceClass(..), Element, Orientation(..))
import Element.Background as Background
import Element.Border as Border
import Html exposing (Html)
import Template.Page.Common as Common


view : { body : Element msg } -> Html msg
view { body } =
    El.layout
        (El.padding 10
            :: Common.layoutAttrs
        )
    <|
        El.el
            (List.append
                [ Border.rounded 10
                , Border.shadow
                    { size = 2
                    , blur = 5
                    , color = Color.lightblue
                    , offset = ( 0, 0 )
                    }
                , El.paddingXY 10 0
                ]
                Common.bodyAttrs
            )
            body
