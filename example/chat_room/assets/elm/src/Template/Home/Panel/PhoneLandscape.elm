module Template.Home.Panel.PhoneLandscape exposing (view)

import Element as El exposing (Element)
import Element.Font as Font
import Template.Home.Panel.Common as Common


view : Common.Config msg c -> Element msg
view { title, description, onClick } =
    El.column
        (List.concat
            [ [ El.height El.fill
              , El.width <| El.px 200
              , El.centerX
              ]
            , Common.onClick onClick
            , Common.containerAttrs
            ]
        )
        [ El.el
            (Font.size 18
                :: Common.headerAttrs
            )
            (El.paragraph
                Common.titleAttrs
                [ El.text title ]
            )
        , El.column
            Common.contentAttrs
            (List.map
                (\para ->
                    El.paragraph
                        (Font.size 16
                            :: Common.descriptionAttrs
                        )
                        [ El.text para ]
                )
                description
            )
        ]
