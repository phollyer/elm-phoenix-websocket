module Template.LobbyMembers.PhonePortrait exposing (view)

import Element as El exposing (Element)


type alias Config c =
    { c
        | members : List User
    }


type alias User =
    { id : String
    , username : String
    }


view : Config c -> Element msg
view config =
    El.column
        [ El.width El.fill
        , El.clipY
        , El.paddingEach
            { left = 0
            , top = 0
            , right = 0
            , bottom = 10
            }
        , El.scrollbarY
        , El.spacing 10
        ]
    <|
        List.map
            (\member ->
                El.text member.username
            )
            config.members
