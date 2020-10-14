module Route exposing
    ( Route(..)
    , fromUrl
    , pushUrl
    , replaceUrl
    )

import Browser.Navigation as Nav
import Url exposing (Url)
import Url.Parser as Parser exposing (Parser, oneOf, s)


type Route
    = Home
    | Root
    | ControlTheSocketConnection


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Home Parser.top
        , Parser.map ControlTheSocketConnection (s "ControlTheSocketConnection")
        ]


fromUrl : Url -> Maybe Route
fromUrl url =
    Parser.parse parser url


pushUrl : Nav.Key -> Route -> Cmd msg
pushUrl key route =
    Nav.pushUrl key (routeToString route)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


routeToString : Route -> String
routeToString route =
    case route of
        Home ->
            "/"

        Root ->
            "/"

        ControlTheSocketConnection ->
            "/ControlTheSocketConnection"
