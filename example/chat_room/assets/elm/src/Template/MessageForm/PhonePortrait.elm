module Template.MessageForm.PhonePortrait exposing (view)

import Element as El exposing (Element)


type alias Config msg c =
    { c
        | value : String
        , onChange : Maybe (String -> msg)
    }


view : Config msg c -> Element msg
view config =
    El.none
