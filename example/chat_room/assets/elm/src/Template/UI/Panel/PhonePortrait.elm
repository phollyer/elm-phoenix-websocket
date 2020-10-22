module Template.UI.Panel.PhonePortrait exposing (render)

import Element as El exposing (Element)
import Element.Font as Font
import Template.UI.Panel.Common as Common


render :
    { p
        | title : String
        , description : List String
        , onClick : Maybe msg
    }
    -> Element msg
render { title, description, onClick } =
    El.column
        (List.concat
            [ [ El.height <|
                    El.maximum 300 El.fill
              , El.width El.fill
              ]
            , Common.onClick onClick
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
