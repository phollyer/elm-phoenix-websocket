module Template.LobbyUser.PhonePortrait exposing (view)

import Element as El exposing (Element)
import Element.Font as Font


type alias Config c =
    { c
        | userId : String
        , username : String
    }


view : Config c -> Element msg
view config =
    El.column
        [ El.width El.fill
        , El.spacing 10
        ]
        [ El.row
            [ El.centerX
            , El.spacing 10
            ]
            [ El.el
                [ Font.bold ]
                (El.text "Username:")
            , El.el
                []
                (El.text config.username)
            ]
        , El.row
            [ El.centerX
            , El.spacing 10
            ]
            [ El.el
                [ Font.bold ]
                (El.text "User ID:")
            , El.el
                []
                (El.text config.userId)
            ]
        ]
