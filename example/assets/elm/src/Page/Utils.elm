module Page.Utils exposing (updatePhoenixSessionWith)

import Phoenix
import Session exposing (Session)


updatePhoenixSessionWith : (Phoenix.Msg -> msg) -> { model | session : Session } -> ( Phoenix.Model, Cmd Phoenix.Msg, Phoenix.PhoenixMsg ) -> ( { model | session : Session }, Cmd msg )
updatePhoenixSessionWith toMsg model ( phoenix, phoenixCmd, _ ) =
    ( { model | session = Session.updatePhoenix phoenix model.session }
    , Cmd.map toMsg phoenixCmd
    )
