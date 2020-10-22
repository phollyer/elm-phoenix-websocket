module Template.UI.Panel.PhonePortrait exposing (render)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Events as Event
import Element.Font as Font


render :
    { p
        | title : String
        , description : List String
        , onClick : Maybe msg
    }
    -> Element msg
render { title, description, onClick } =
    let
        onClick_ =
            case onClick of
                Nothing ->
                    []

                Just msg ->
                    [ Event.onClick msg ]
    in
    El.column
        (List.append
            onClick_
            [ Background.color Color.steelblue
            , Border.rounded 20
            , Border.width 1
            , Border.color Color.steelblue
            , El.height <|
                El.maximum 300 El.fill
            , El.width <| El.px 250
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
            ]
        )
        [ El.el
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
            , Font.size 20
            ]
            (El.paragraph
                [ El.width El.fill
                , Font.center
                ]
                [ El.text title ]
            )
        , El.column
            [ Background.color Color.lightskyblue
            , El.height El.fill
            , El.width El.fill
            , El.padding 10
            , El.spacing 10
            ]
            (List.map
                (\para ->
                    El.paragraph
                        [ El.width El.fill
                        , Font.justify
                        , Font.size 16
                        ]
                        [ El.text para ]
                )
                description
            )
        ]
