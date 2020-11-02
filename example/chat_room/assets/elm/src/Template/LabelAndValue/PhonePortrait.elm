module Template.LabelAndValue.PhonePortrait exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Font as Font


type alias Config c =
    { c
        | label : String
        , value : String
    }


view : Config c -> Element msg
view config =
    El.row
        [ El.width El.fill
        , El.spacing 20
        ]
        [ El.el
            [ Font.color Color.darkslateblue ]
            (El.text config.label)
        , El.el
            [ Font.color Color.black ]
            (El.text config.value)
        ]
