module Template.LobbyForm.PhonePortrait exposing (view)

import Element as El exposing (Element)


type alias Config msg c =
    { c
        | usernameInput : Element msg
        , submitBtn : Element msg
    }


view : Config msg c -> Element msg
view config =
    El.column
        [ El.width El.fill
        , El.spacing 20
        ]
        [ config.usernameInput
        , config.submitBtn
        ]
