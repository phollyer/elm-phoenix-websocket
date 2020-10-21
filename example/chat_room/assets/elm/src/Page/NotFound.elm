module Page.NotFound exposing (view)

import Html exposing (Html)
import View.Layout as Layout


view : { title : String, content : Html msg }
view =
    { title = "Not Found"
    , content =
        Layout.init
            |> Layout.render Layout.NotFound
    }
