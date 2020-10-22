module Template.UI.Panel.Desktop exposing (render)

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
            [ [ El.height El.fill
              , El.width <| El.px 250
              , El.centerX
              ]
            , Common.onClick onClick
            , Common.containerAttrs
            ]
        )
        [ El.el
            (Font.size 20
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
                        (Font.size 18
                            :: Common.descriptionAttrs
                        )
                        [ El.text para ]
                )
                description
            )
        ]
