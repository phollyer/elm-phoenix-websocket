module Page.NotFound exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Font as Font


view : { title : String, content : Element msg }
view =
    { title = "Not Found"
    , content =
        El.el
            [ El.centerX
            , El.centerY
            , Font.size 40
            , Font.color Color.darkslateblue
            ]
            (El.text "Page Not Found")
    }
