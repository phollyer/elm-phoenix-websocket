module Template.Panel.PhoneLandscape exposing (view)

import Element as El exposing (Element)
import Element.Font as Font
import Template.Panel.Common as Common


view : Common.Config msg c -> Element msg
view { title, description, onClick } =
    El.column
        (List.concat
            [ Common.onClick onClick
            , Common.containerAttrs
            ]
        )
        [ El.el
            (Font.size 16
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
                        (Font.size 14
                            :: Common.descriptionAttrs
                        )
                        [ El.text para ]
                )
                description
            )
        ]
