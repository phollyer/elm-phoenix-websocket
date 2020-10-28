module View.Feedback exposing
    ( Config
    , elements
    , group
    , init
    , view
    )

import Element exposing (Device, DeviceClass(..), Element, Orientation(..))
import Template.Feedback.PhoneLandscape as PhoneLandscape
import Template.Feedback.PhonePortrait as PhonePortrait
import View.Group as Group


type Config msg
    = Config
        { elements : List (Element msg)
        , group : Group.Config
        , layout : Maybe (List Int)
        }


init : Config msg
init =
    Config
        { elements = []
        , group = Group.init
        , layout = Nothing
        }


view : Device -> Config msg -> Element msg
view ({ class, orientation } as device) (Config config) =
    Group.orderElementsForDevice device config.group config
        |> Group.layoutForDevice device config.group
        |> (case ( class, orientation ) of
                ( Phone, Portrait ) ->
                    PhonePortrait.view

                _ ->
                    PhoneLandscape.view
           )


elements : List (Element msg) -> Config msg -> Config msg
elements list (Config config) =
    Config { config | elements = list }


group : Group.Config -> Config msg -> Config msg
group group_ (Config config) =
    Config { config | group = group_ }
