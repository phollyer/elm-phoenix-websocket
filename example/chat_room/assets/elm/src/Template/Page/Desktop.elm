module Template.Page.Desktop exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Border as Border
import Html exposing (Html)
import Template.Page.Common as Common


view : { body : Element msg } -> Html msg
view { body } =
    El.layout
        (El.padding 30
            :: Common.layoutAttrs
        )
    <|
        El.el
            (List.append
                [ Border.rounded 30
                , Border.shadow
                    { size = 5
                    , blur = 20
                    , color = Color.lightblue
                    , offset = ( 0, 0 )
                    }
                , El.paddingXY 30 0
                ]
                Common.bodyAttrs
            )
            body
