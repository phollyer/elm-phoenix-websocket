module Template.Layout.NotFound exposing (render)

import Element as El exposing (Element)
import Element.Font as Font


render : Element msg
render =
    El.el
        [ El.centerX
        , El.centerY
        , Font.size 40
        ]
        (El.text " Page Not Found")
