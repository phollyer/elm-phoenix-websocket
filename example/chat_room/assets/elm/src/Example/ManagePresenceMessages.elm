module Example.ManagePresenceMessages exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Element as El exposing (Device, DeviceClass(..), Element, Orientation(..))
import Extra.String as String
import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode as JE exposing (Value)
import Json.Encode.Extra exposing (maybe)
import Phoenix
import UI
import View.ApplicableFunctions as ApplicableFunctions
import View.Button as Button
import View.Example as Example
import View.ExampleControls as ExampleControls
import View.Feedback as Feedback
import View.FeedbackContent as FeedbackContent
import View.FeedbackInfo as FeedbackInfo
import View.FeedbackPanel as FeedbackPanel
import View.Group as Group
import View.LabelAndValue as LabelAndValue
import View.UsefulFunctions as UsefulFunctions



{- Init -}


init : Maybe ID -> Device -> Phoenix.Model -> Model
init maybeExampleId device phoenix =
    { device = device
    , phoenix = phoenix
    , messages = []
    , receiveMessages = True
    , maybeExampleId = maybeExampleId
    , maybeUserId = Nothing
    , presenceState = []
    }



{- Model -}


type alias Model =
    { device : Device
    , phoenix : Phoenix.Model
    , messages : List PresenceInfo
    , receiveMessages : Bool
    , maybeExampleId : Maybe ID
    , maybeUserId : Maybe ID
    , presenceState : List { id : String, meta : Meta }
    }


type alias PresenceInfo =
    { topic : String
    , event : String
    , payload : Value
    }


type alias ID =
    String


type alias Meta =
    { exampleState : ExampleState }


type ExampleState
    = NotJoined
    | Joining
    | Joined
    | Leaving


type Action
    = Join
    | Leave
    | On
    | Off


pushConfig : Phoenix.Push
pushConfig =
    { topic = ""
    , event = ""
    , payload = JE.null
    , timeout = Nothing
    , retryStrategy = Phoenix.Drop
    , ref = Nothing
    }



{- Update -}


type Msg
    = GotControlClick Action
    | GotRemoteControlClick String Action
    | GotPhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotControlClick action ->
            case action of
                Join ->
                    model.phoenix
                        |> Phoenix.setJoinConfig
                            { topic = "example:manage_presence_messages"
                            , events = []
                            , payload =
                                JE.object
                                    [ ( "user_id", maybe JE.string model.maybeUserId ) ]
                            , timeout = Nothing
                            }
                        |> Phoenix.join "example:manage_presence_messages"
                        |> updatePhoenix model

                Leave ->
                    Phoenix.leave "example:manage_presence_messages" model.phoenix
                        |> updatePhoenix model

                On ->
                    ( { model | receiveMessages = True }
                    , Phoenix.socketPresenceMessagesOn model.phoenix
                        |> Cmd.map GotPhoenixMsg
                    )

                Off ->
                    ( { model | receiveMessages = False }
                    , Phoenix.socketPresenceMessagesOff model.phoenix
                        |> Cmd.map GotPhoenixMsg
                    )

        GotRemoteControlClick id action ->
            ( model, Cmd.none )

        GotPhoenixMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update subMsg model.phoenix
                        |> updatePhoenix model
            in
            case Phoenix.phoenixMsg newModel.phoenix of
                Phoenix.SocketMessage (Phoenix.PresenceMessage info) ->
                    ( { newModel
                        | messages =
                            if String.startsWith "example_controller" info.topic then
                                newModel.messages

                            else
                                info :: newModel.messages
                      }
                    , cmd
                    )

                Phoenix.ChannelResponse (Phoenix.JoinOk "example:manage_presence_messages" payload) ->
                    Phoenix.push
                        { pushConfig
                            | topic = controllerTopic newModel.maybeExampleId
                            , event = "joined_example"
                        }
                        newModel.phoenix
                        |> updatePhoenix newModel
                        |> batch [ cmd ]

                Phoenix.ChannelResponse (Phoenix.LeaveOk "example:manage_presence_messages") ->
                    Phoenix.push
                        { pushConfig
                            | topic = controllerTopic newModel.maybeExampleId
                            , event = "left_example"
                        }
                        newModel.phoenix
                        |> updatePhoenix newModel
                        |> batch [ cmd ]

                {- Remote Control -}
                Phoenix.ChannelResponse (Phoenix.JoinOk topic payload) ->
                    case Phoenix.topicParts topic of
                        ( "example_controller", "control" ) ->
                            case decodeExampleId payload of
                                Ok exampleId_ ->
                                    Phoenix.batch
                                        [ Phoenix.leave "example_controller:control"
                                        , Phoenix.join (controllerTopic (Just exampleId_))
                                        ]
                                        newModel.phoenix
                                        |> updatePhoenix { newModel | maybeExampleId = Just exampleId_ }
                                        |> batch [ cmd ]

                                _ ->
                                    ( newModel, cmd )

                        ( "example_controller", _ ) ->
                            case decodeUserId payload of
                                Ok id ->
                                    ( { newModel | maybeUserId = Just id }
                                    , Cmd.batch
                                        [ cmd
                                        , Cmd.map GotPhoenixMsg <|
                                            Phoenix.addEvents (controllerTopic newModel.maybeExampleId)
                                                [ "join_example"
                                                , "leave_example"
                                                ]
                                                newModel.phoenix
                                        ]
                                    )

                                _ ->
                                    ( newModel, cmd )

                        _ ->
                            ( newModel, cmd )

                Phoenix.ChannelEvent _ event payload ->
                    case ( event, decodeUserId payload ) of
                        ( "join_example", Ok userId ) ->
                            if newModel.maybeUserId == Just userId then
                                model.phoenix
                                    |> Phoenix.setJoinConfig
                                        { topic = "example:manage_presence_messages"
                                        , events = []
                                        , payload =
                                            JE.object
                                                [ ( "user_id", JE.string userId ) ]
                                        , timeout = Nothing
                                        }
                                    |> Phoenix.batch
                                        [ Phoenix.join "example:manage_presence_messages"
                                        , Phoenix.push
                                            { pushConfig
                                                | topic = controllerTopic newModel.maybeExampleId
                                                , event = "joining_example"
                                            }
                                        ]
                                    |> updatePhoenix newModel

                            else
                                ( newModel, cmd )

                        ( "leave_example", Ok userId ) ->
                            if newModel.maybeUserId == Just userId then
                                model.phoenix
                                    |> Phoenix.batch
                                        [ Phoenix.leave "example:manage_presence_messages"
                                        , Phoenix.push
                                            { pushConfig
                                                | topic = controllerTopic newModel.maybeExampleId
                                                , event = "leaving_example"
                                            }
                                        ]
                                    |> updatePhoenix newModel

                            else
                                ( newModel, cmd )

                        _ ->
                            ( newModel, cmd )

                _ ->
                    ( model, Cmd.none )


controllerTopic : Maybe ID -> String
controllerTopic maybeId =
    case maybeId of
        Just id ->
            "example_controller:" ++ id

        Nothing ->
            ""


updatePhoenix : Model -> ( Phoenix.Model, Cmd Phoenix.Msg ) -> ( Model, Cmd Msg )
updatePhoenix model ( phoenix, phoenixCmd ) =
    ( { model | phoenix = phoenix }
    , Cmd.map GotPhoenixMsg phoenixCmd
    )


toPresenceState : List Phoenix.Presence -> List { id : String, meta : Meta }
toPresenceState presences =
    List.map toPresence presences


toPresence : Phoenix.Presence -> { id : String, meta : Meta }
toPresence presence =
    { id = presence.id
    , meta =
        case presence.metas of
            -- There will only ever be one meta in the list because each new
            -- join will be considered a new user, so a user cannot have
            -- multiple joins.
            meta :: _ ->
                case decodeMeta meta of
                    Ok m ->
                        m

                    _ ->
                        { exampleState = NotJoined }

            [] ->
                { exampleState = NotJoined }
    }


batch : List (Cmd Msg) -> ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
batch cmds ( model, cmd ) =
    ( model
    , Cmd.batch (cmd :: cmds)
    )



{- exampleId is a unique ID supplied by "example_controller:control" that
   is used to identify the example in each tab. The tabs can then all join the
   same controlling Channel which routes messages between them.
-}


getExampleId : Model -> ( Model, Cmd Msg )
getExampleId model =
    case model.maybeExampleId of
        Nothing ->
            Phoenix.join "example_controller:control" model.phoenix
                |> updatePhoenix model

        _ ->
            ( model, Cmd.none )



{- Decoders -}


decodeExampleId : Value -> Result JD.Error String
decodeExampleId payload =
    JD.decodeValue (JD.field "example_id" JD.string) payload


decodeUserId : Value -> Result JD.Error String
decodeUserId payload =
    JD.decodeValue (JD.field "user_id" JD.string) payload


metaDecoder : JD.Decoder Meta
metaDecoder =
    JD.succeed
        Meta
        |> andMap
            (JD.field "example_state" JD.string
                |> JD.andThen stateDecoder
            )


stateDecoder : String -> JD.Decoder ExampleState
stateDecoder state =
    case state of
        "Joined" ->
            JD.succeed Joined

        "Joining" ->
            JD.succeed Joining

        "Leaving" ->
            JD.succeed Leaving

        "Not Joined" ->
            JD.succeed NotJoined

        _ ->
            JD.fail <|
                "Not a valid Example State: "
                    ++ state


decodeMeta : Value -> Result JD.Error Meta
decodeMeta payload =
    JD.decodeValue metaDecoder payload



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map GotPhoenixMsg <|
        Phoenix.subscriptions model.phoenix



{- View -}


view : Model -> Element Msg
view model =
    Example.init
        |> Example.description description
        |> Example.controls (controls model)
        |> Example.feedback (feedback model)
        |> Example.view model.device



{- Description -}


description : List (Element msg)
description =
    [ UI.paragraph
        [ El.text "Choose whether to receive Channel messages as an incoming Socket message." ]
    ]



{- Controls -}


controls : Model -> Element Msg
controls { device, phoenix, receiveMessages } =
    ExampleControls.init
        |> ExampleControls.elements
            [ join device GotControlClick (not <| Phoenix.channelJoined "example:manage_presence_messages" phoenix)
            , on device (not receiveMessages)
            , off device receiveMessages
            , leave device GotControlClick (Phoenix.channelJoined "example:manage_presence_messages" phoenix)
            ]
        |> ExampleControls.group
            (Group.init
                |> Group.layouts
                    [ ( Phone, Portrait, [ 2, 2 ] ) ]
                |> Group.order
                    [ ( Phone, Portrait, [ 0, 2, 3, 1 ] ) ]
            )
        |> ExampleControls.view device


join : Device -> (Action -> Msg) -> Bool -> Element Msg
join device onPress enabled =
    Button.init
        |> Button.label "Join"
        |> Button.onPress (Just (onPress Join))
        |> Button.enabled enabled
        |> Button.view device


leave : Device -> (Action -> Msg) -> Bool -> Element Msg
leave device onPress enabled =
    Button.init
        |> Button.label "Leave"
        |> Button.onPress (Just (onPress Leave))
        |> Button.enabled enabled
        |> Button.view device


on : Device -> Bool -> Element Msg
on device enabled =
    Button.init
        |> Button.label "Presence On"
        |> Button.onPress (Just (GotControlClick On))
        |> Button.enabled enabled
        |> Button.view device


off : Device -> Bool -> Element Msg
off device enabled =
    Button.init
        |> Button.label "Presence Off"
        |> Button.onPress (Just (GotControlClick Off))
        |> Button.enabled enabled
        |> Button.view device



{- Remote ExampleControls -}


remoteControls : Device -> Phoenix.Model -> Model -> List (Element Msg)
remoteControls device phoenix { maybeUserId, presenceState } =
    List.filterMap (maybeRemoteControl maybeUserId device) presenceState


maybeRemoteControl : Maybe ID -> Device -> { id : String, meta : Meta } -> Maybe (Element Msg)
maybeRemoteControl userId device { id, meta } =
    if userId == Just id then
        Nothing

    else
        Just <|
            (ExampleControls.init
                |> ExampleControls.userId (Just id)
                |> ExampleControls.elements
                    [ join device (GotRemoteControlClick id) (meta.exampleState == NotJoined)
                    , leave device (GotRemoteControlClick id) (meta.exampleState == Joined)
                    ]
                |> ExampleControls.group
                    (Group.init
                        |> Group.layouts [ ( Phone, Portrait, [ 2 ] ) ]
                    )
                |> ExampleControls.view device
            )



{- Feedback -}


feedback : Model -> Element Msg
feedback { device, phoenix, messages } =
    Feedback.init
        |> Feedback.elements
            [ FeedbackPanel.init
                |> FeedbackPanel.title "Info"
                |> FeedbackPanel.static (static device messages)
                |> FeedbackPanel.scrollable (scrollable device messages)
                |> FeedbackPanel.view device
            , FeedbackPanel.init
                |> FeedbackPanel.title "Applicable Functions"
                |> FeedbackPanel.scrollable [ applicableFunctions device ]
                |> FeedbackPanel.view device
            , FeedbackPanel.init
                |> FeedbackPanel.title "Useful Functions"
                |> FeedbackPanel.scrollable [ usefulFunctions device phoenix ]
                |> FeedbackPanel.view device
            ]
        |> Feedback.group
            (Group.init
                |> Group.layouts
                    [ ( Phone, Landscape, [ 1, 2 ] )
                    , ( Tablet, Portrait, [ 1, 2 ] )
                    , ( Tablet, Landscape, [ 1, 2 ] )
                    , ( Desktop, Portrait, [ 1, 2 ] )
                    ]
            )
        |> Feedback.view device


static : Device -> List PresenceInfo -> List (Element Msg)
static device messages =
    [ LabelAndValue.init
        |> LabelAndValue.label "Message Count"
        |> LabelAndValue.value (messages |> List.length |> String.fromInt)
        |> LabelAndValue.view device
    ]


scrollable : Device -> List PresenceInfo -> List (Element Msg)
scrollable device messages =
    List.map
        (\info ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "SocketMessage")
                |> FeedbackContent.label "PresenceMessage"
                |> FeedbackContent.element (presenceInfo device info)
                |> FeedbackContent.view device
        )
        messages


presenceInfo : Device -> PresenceInfo -> Element Msg
presenceInfo device info =
    FeedbackInfo.init
        |> FeedbackInfo.topic info.topic
        |> FeedbackInfo.event info.event
        |> FeedbackInfo.payload info.payload
        |> FeedbackInfo.view device


applicableFunctions : Device -> Element Msg
applicableFunctions device =
    ApplicableFunctions.init
        |> ApplicableFunctions.functions
            [ "Phoenix.join"
            , "Phoenix.socketPresenceMessagesOn"
            , "Phoenix.socketPresenceMessagesOff"
            , "Phoeinx.leave"
            ]
        |> ApplicableFunctions.view device


usefulFunctions : Device -> Phoenix.Model -> Element Msg
usefulFunctions device phoenix =
    UsefulFunctions.init
        |> UsefulFunctions.functions
            [ ( "Phoenix.socketState", Phoenix.socketStateToString phoenix )
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix |> String.printQuoted )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.printBool )
            , ( "Phoenix.channelJoined", Phoenix.channelJoined "example:manage_presence_messages" phoenix |> String.printBool )
            , ( "Phoenix.joinedChannels"
              , Phoenix.joinedChannels phoenix
                    |> List.filter (String.startsWith "example:")
                    |> String.printList
              )
            , ( "Phoenix.lastPresenceJoin", Phoenix.lastPresenceJoin "example:manage_presence_messages" phoenix |> String.printMaybe "Presence" )
            , ( "Phoenix.lastPresenceLeave", Phoenix.lastPresenceLeave "example:manage_presence_messages" phoenix |> String.printMaybe "Presence" )
            ]
        |> UsefulFunctions.view device
