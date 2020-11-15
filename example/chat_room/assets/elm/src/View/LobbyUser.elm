module View.LobbyUser exposing
    ( init
    , userId
    , username
    , view
    )

import Device exposing (Device)
import Element as El exposing (Element)
import Element.Font as Font



{- Model -}


type Config
    = Config
        { userId : String
        , username : String
        }


init : Config
init =
    Config
        { userId = ""
        , username = ""
        }


username : String -> Config -> Config
username name (Config config) =
    Config { config | username = name }


userId : String -> Config -> Config
userId id (Config config) =
    Config { config | userId = id }



{- View -}


view : Device -> Config -> Element msg
view _ (Config config) =
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
