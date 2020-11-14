module View.ExampleControls exposing
    ( Config
    , elements
    , group
    , init
    , userId
    , view
    )

import Device exposing (Device)
import Element exposing (DeviceClass(..), Element, Orientation(..))
import Template.ExampleControls.PhoneLandscape as PhoneLandscape
import Template.ExampleControls.PhonePortrait as PhonePortrait
import View.Group as Group


type Config msg
    = Config
        { userId : Maybe String
        , elements : List (Element msg)
        , layout : Maybe (List Int)
        , group : Group.Config
        }


init : Config msg
init =
    Config
        { userId = Nothing
        , elements = []
        , layout = Nothing
        , group = Group.init
        }


view : Device -> Config msg -> Element msg
view ({ class, orientation } as device) (Config config) =
    case ( class, orientation ) of
        ( Phone, Portrait ) ->
            Group.orderElementsForDevice device config.group config
                |> Group.layoutForDevice device config.group
                |> PhonePortrait.view

        _ ->
            Group.orderElementsForDevice device config.group config
                |> Group.layoutForDevice device config.group
                |> PhoneLandscape.view


{-| -}
userId : Maybe String -> Config msg -> Config msg
userId maybeId (Config config) =
    Config { config | userId = maybeId }


elements : List (Element msg) -> Config msg -> Config msg
elements list (Config config) =
    Config { config | elements = list }


group : Group.Config -> Config msg -> Config msg
group group_ (Config config) =
    Config { config | group = group_ }
