module Template.UI.Example exposing
    ( button
    , code
    , paragraph
    )

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Element.Input as Input


paragraph : List (Element msg) -> Element msg
paragraph content =
    El.paragraph
        [ El.spacing 10 ]
        content


code : String -> Element msg
code text =
    El.el
        [ Font.family [ Font.typeface "Roboto Mono" ]
        , Background.color Color.lightgrey
        , El.padding 2
        , Border.width 1
        , Border.color Color.black
        , Font.size 16
        , Font.color Color.black
        ]
        (El.text text)


type alias Button a msg =
    { enabled : Bool
    , label : String
    , example : a
    , onPress : a -> msg
    }


button : Button a msg -> Element msg
button btn =
    let
        attrs =
            if btn.enabled then
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
        { label = El.text btn.label
        , onPress =
            if btn.enabled then
                Just (btn.onPress btn.example)

            else
                Nothing
        }
