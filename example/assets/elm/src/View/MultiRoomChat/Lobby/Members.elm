module View.MultiRoomChat.Lobby.Members exposing
    ( init
    , members
    , user
    , view
    )

import Colors.Opaque as Color
import Device exposing (Device)
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Types exposing (User, initUser)



{- Model -}


type Config
    = Config
        { members : List User
        , user : User
        }


init : Config
init =
    Config
        { members = []
        , user = initUser
        }


members : List User -> Config -> Config
members users (Config config) =
    Config { config | members = users }


user : User -> Config -> Config
user currentUser (Config config) =
    Config { config | user = currentUser }



{- View -}


view : Device -> Config -> Element msg
view _ config =
    El.column
        [ Border.rounded 10
        , Background.color Color.steelblue
        , El.padding 10
        , El.spacing 10
        , El.width El.fill
        , Font.color Color.skyblue
        ]
        [ El.el
            [ El.centerX ]
            (El.text "Members")
        , El.paragraph
            [ El.width El.fill ]
            [ toMembers config ]
        ]


toMembers : Config -> Element msg
toMembers (Config config) =
    List.filter (\member -> member /= config.user) config.members
        |> List.map .username
        |> List.append [ "You" ]
        |> List.intersperse ", "
        |> String.concat
        |> El.text
