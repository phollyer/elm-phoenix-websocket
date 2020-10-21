module Page.NotFound exposing (view)

import Element exposing (Element)
import View.Layout as Layout


view : { title : String, content : Element msg }
view =
    { title = "Not Found"
    , content =
        Layout.init
            |> Layout.render Layout.NotFound
    }
