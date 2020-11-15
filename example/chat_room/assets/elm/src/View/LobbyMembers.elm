module View.LobbyMembers exposing
    ( init
    , members
    , view
    )

import Device exposing (Device)
import Element as El exposing (Element)



{- Model -}


type Config
    = Config { members : List User }


type alias User =
    { id : String
    , username : String
    }


init : Config
init =
    Config
        { members = [] }


members : List User -> Config -> Config
members users (Config config) =
    Config { config | members = users }



{- View -}


view : Device -> Config -> Element msg
view _ (Config config) =
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
