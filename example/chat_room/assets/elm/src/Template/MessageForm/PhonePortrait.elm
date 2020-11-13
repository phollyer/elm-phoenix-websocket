module Template.MessageForm.PhonePortrait exposing (view)

import Element as El exposing (Element)
import Element.Input as Input


type alias Config msg c =
    { c
        | inputField : Element msg
        , submitBtn : Element msg
    }


view : Config msg c -> Element msg
view config =
    El.column
        [ El.spacing 10
        , El.width El.fill
        ]
        [ config.inputField
        , config.submitBtn
        ]
