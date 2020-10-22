module Template.UI.Button.Default exposing (..)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input


render :
    { b
        | enabled : Bool
        , label : String
        , example : Maybe example
        , onPress : Maybe (example -> msg)
    }
    -> Element msg
render config =
    let
        attrs =
            if config.enabled then
                [ Background.color Color.darkseagreen
                , El.mouseOver <|
                    [ Border.shadow
                        { size = 1
                        , blur = 2
                        , color = Color.seagreen
                        , offset = ( 0, 0 )
                        }
                    , Font.size 31
                    ]
                , Font.color Color.darkolivegreen
                ]

            else
                [ Background.color Color.grey
                , Font.color Color.darkgrey
                ]
    in
    Input.button
        (List.append
            attrs
            [ Border.rounded 10
            , El.padding 10
            , Font.size 30
            ]
        )
        { label = El.text config.label
        , onPress =
            case ( config.onPress, config.example ) of
                ( Just onPress, Just example ) ->
                    Just (onPress example)

                _ ->
                    Nothing
        }
