module Template.Page.Tablet exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Border as Border
import Html exposing (Html)
import Template.Page.Common as Common


view : Element msg -> Html msg
view body =
    El.layout
        (El.padding 20
            :: Common.layoutAttrs
        )
    <|
        El.el
            (List.append
                [ Border.rounded 20
                , Border.shadow
                    { size = 3
                    , blur = 10
                    , color = Color.lightblue
                    , offset = ( 0, 0 )
                    }
                , El.paddingXY 20 0
                ]
                Common.bodyAttrs
            )
            body
