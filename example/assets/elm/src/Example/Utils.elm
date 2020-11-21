module Example.Utils exposing
    ( batch
    , updatePhoenixWith
    )

import Phoenix


batch : List (Cmd msg) -> ( model, Cmd msg ) -> ( model, Cmd msg )
batch cmds ( model, cmd ) =
    ( model
    , Cmd.batch (cmd :: cmds)
    )


updatePhoenixWith : (Phoenix.Msg -> msg) -> { model | phoenix : Phoenix.Model } -> ( Phoenix.Model, Cmd Phoenix.Msg ) -> ( { model | phoenix : Phoenix.Model }, Cmd msg )
updatePhoenixWith toMsg model ( phoenix, phoenixCmd ) =
    ( { model | phoenix = phoenix }
    , Cmd.map toMsg phoenixCmd
    )
