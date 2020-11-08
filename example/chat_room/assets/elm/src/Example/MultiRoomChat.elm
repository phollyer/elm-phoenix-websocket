module Example.MultiRoomChat exposing
    ( Model
    , init
    )

import Phoenix



{- Init -}


init : Phoenix.Model -> Model
init phoenix =
    { phoenix = phoenix }



{- Model -}


type alias Model =
    { phoenix : Phoenix.Model }
