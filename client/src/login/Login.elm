module Login exposing (main)

import Browser
import Browser.Navigation as Nav
import Components
import Element as Elem
import Element.Background as ElemBg
import Element.Border as ElemBorder
import Element.Font as ElemFont
import Element.Input as ElemInput
import Element.Region as ElemRegion
import Html exposing (Html)
import Http
import Json.Decode as JsonDecode
import Json.Encode as JsonEncode
import PageStyle as Style



-- MAIN


main : Program () Model Msg
main =
    Browser.element
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }



-- MODEL


type Model
    = Login LoginForm
    | SignUp SignUpForm


type alias SignUpForm =
    { username : String
    , email : String
    , password : String
    , serverResponse : String
    }


type alias LoginForm =
    { username : String
    , password : String
    , serverResponse : String
    }


emptyLoginForm : LoginForm
emptyLoginForm =
    LoginForm "" "" ""


emptySignUpForm : SignUpForm
emptySignUpForm =
    SignUpForm "" "" "" ""



-- INIT


init : () -> ( Model, Cmd msg )
init _ =
    ( Login emptyLoginForm
    , Cmd.none
    )



-- UPDATE


baseUrl : String
baseUrl =
    "http://127.0.0.1:8000"


loginAuthUrl : String
loginAuthUrl =
    baseUrl ++ "/api/login"


dashboardUrl : String
dashboardUrl =
    baseUrl ++ "/dashboard"


signUpUrl : String
signUpUrl =
    baseUrl ++ "/api/signup"


type Msg
    = NoOp
    | LoginMsg LoginMsgT
    | SignUpMsg SignUpMsgT


type LoginMsgT
    = UpdateLoginForm LoginForm
    | GotoSignUp
    | SendLoginRequest
    | ReceivedLoginRequestResponse (Result Http.Error String)


type SignUpMsgT
    = UpdateSignUpForm SignUpForm
    | GotoLogin
    | SendSignUpRequest
    | ReceivedSignUpRequestResponse (Result Http.Error String)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        loginForm =
            case model of
                Login form ->
                    form

                _ ->
                    emptyLoginForm

        signUpForm =
            case model of
                SignUp form ->
                    form

                _ ->
                    emptySignUpForm
    in
    case msg of
        NoOp ->
            ( model
            , Cmd.none
            )

        LoginMsg loginMsg ->
            loginUpdateHandler loginMsg loginForm

        SignUpMsg signUpMsg ->
            signUpUpdateHandler signUpMsg signUpForm


loginUpdateHandler : LoginMsgT -> LoginForm -> ( Model, Cmd Msg )
loginUpdateHandler msg loginForm =
    case msg of
        UpdateLoginForm newForm ->
            ( Login newForm
            , Cmd.none
            )

        GotoSignUp ->
            ( SignUp emptySignUpForm
            , Cmd.none
            )

        SendLoginRequest ->
            ( Login loginForm
            , Cmd.map LoginMsg <| sendLoginRequest loginForm
            )

        ReceivedLoginRequestResponse result ->
            let
                invalidCredsResponse =
                    "Invalid username or password!"

                somethingWentWrongResponse =
                    "Something went wrong, please try again later!"
            in
            case result of
                Err httpError ->
                    case httpError of
                        Http.BadStatus status ->
                            case status of
                                401 ->
                                    ( Login { loginForm | serverResponse = invalidCredsResponse }
                                    , Cmd.none
                                    )

                                _ ->
                                    ( Login { loginForm | serverResponse = somethingWentWrongResponse }
                                    , Cmd.none
                                    )

                        _ ->
                            ( Login { loginForm | serverResponse = somethingWentWrongResponse }
                            , Cmd.none
                            )

                Ok responseString ->
                    ( Login { loginForm | serverResponse = responseString }
                    , Nav.load dashboardUrl
                    )


encodeLoginCreds : LoginForm -> JsonEncode.Value
encodeLoginCreds loginForm =
    JsonEncode.object
        [ ( "username", JsonEncode.string loginForm.username )
        , ( "password", JsonEncode.string loginForm.password )
        ]


sendLoginRequest : LoginForm -> Cmd LoginMsgT
sendLoginRequest loginForm =
    Http.post
        { url = loginAuthUrl
        , body = Http.jsonBody <| encodeLoginCreds loginForm
        , expect = Http.expectString ReceivedLoginRequestResponse
        }


signUpUpdateHandler : SignUpMsgT -> SignUpForm -> ( Model, Cmd Msg )
signUpUpdateHandler msg signUpForm =
    case msg of
        UpdateSignUpForm newForm ->
            ( SignUp newForm
            , Cmd.none
            )

        GotoLogin ->
            ( Login emptyLoginForm
            , Cmd.none
            )

        SendSignUpRequest ->
            ( SignUp signUpForm
            , Cmd.map SignUpMsg <| sendSignUpRequest signUpForm
            )

        ReceivedSignUpRequestResponse result ->
            let
                usernameTaken =
                    "Username already in use, please a different username!"

                invalidUserOrEmail =
                    "Username or Email invalid, please try again!"

                somethingWentWrongResponse =
                    "Something went wrong, please try again later!"
            in
            case result of
                Err httpError ->
                    case httpError of
                        Http.BadStatus status ->
                            case status of
                                409 ->
                                    ( SignUp { signUpForm | serverResponse = usernameTaken }
                                    , Cmd.none
                                    )

                                400 ->
                                    ( SignUp { signUpForm | serverResponse = invalidUserOrEmail }
                                    , Cmd.none
                                    )

                                _ ->
                                    ( SignUp { signUpForm | serverResponse = somethingWentWrongResponse }
                                    , Cmd.none
                                    )

                        _ ->
                            ( SignUp { signUpForm | serverResponse = somethingWentWrongResponse }
                            , Cmd.none
                            )

                Ok responseString ->
                    ( Login { emptyLoginForm | serverResponse = "Account created, please login!" }
                    , Cmd.none
                    )


encodeSignUpCreds : SignUpForm -> JsonEncode.Value
encodeSignUpCreds signUpForm =
    JsonEncode.object
        [ ( "username", JsonEncode.string signUpForm.username )
        , ( "password", JsonEncode.string signUpForm.password )
        , ( "email", JsonEncode.string signUpForm.email )
        ]


sendSignUpRequest : SignUpForm -> Cmd SignUpMsgT
sendSignUpRequest signUpForm =
    Http.post
        { url = signUpUrl
        , body = Http.jsonBody <| encodeSignUpCreds signUpForm
        , expect = Http.expectString ReceivedSignUpRequestResponse
        }



-- SUBSCRIPTIONS


subscriptions : Model -> Sub msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    let
        formView =
            case model of
                Login loginForm ->
                    loginView loginForm

                SignUp signUpForm ->
                    signUpView signUpForm
    in
    Elem.layout
        [ ElemBg.color Style.baseBgColour
        , ElemFont.color Style.baseFontFgColor
        ]
    <|
        Elem.column
            [ Elem.width Elem.fill
            , Elem.height Elem.fill
            , Elem.centerY
            , Elem.centerX
            ]
            [ Components.logoOnlyNavBar
            , Elem.column
                [ Elem.width Elem.shrink
                , Elem.height Elem.shrink
                , Elem.centerX
                , Elem.centerY
                , Elem.padding 60
                , Elem.spacing 25
                , ElemBg.color Style.elementBgColour
                , ElemBorder.rounded 15
                , ElemBorder.shadow
                    { size = 5.0
                    , offset = ( 0.0, 0.0 )
                    , blur = 30.0
                    , color = Elem.rgb 0.05 0.05 0.05
                    }
                ]
                [ formHead
                , formView
                ]
            ]


formHead : Elem.Element Msg
formHead =
    Elem.column
        [ Elem.centerX
        ]
        [ Elem.row
            [ ElemRegion.heading 1
            , ElemFont.size 36
            ]
            [ Elem.text "Welcome to Breakdown!" ]

        -- Acts as spacer
        , Elem.row
            [ Elem.centerX
            , Elem.height (Elem.px 30)
            ]
            []
        ]


loginView : LoginForm -> Elem.Element Msg
loginView loginForm =
    let
        serverResponseBox =
            case loginForm.serverResponse of
                "" ->
                    Elem.text ""

                _ ->
                    Elem.el
                        [ Elem.centerX
                        , Elem.width Elem.shrink
                        , Elem.height Elem.shrink
                        ]
                    <|
                        Elem.el
                            [ Elem.paddingXY 10 10
                            , ElemBg.color <| Elem.rgb 0.55 0 0
                            , ElemBorder.rounded 5
                            ]
                        <|
                            Elem.text loginForm.serverResponse
    in
    Elem.column
        [ Elem.centerX
        , Elem.spacing 30
        ]
        [ ElemInput.username
            [ ElemBg.color Style.inputFieldBgColour
            ]
            { text = loginForm.username
            , placeholder = Nothing
            , label = ElemInput.labelAbove [ ElemFont.size 20 ] (Elem.text "Username")
            , onChange = \newUsername -> LoginMsg <| UpdateLoginForm { loginForm | username = newUsername }
            }
        , ElemInput.currentPassword
            [ ElemBg.color Style.inputFieldBgColour
            ]
            { text = loginForm.password
            , placeholder = Nothing
            , label = ElemInput.labelAbove [ ElemFont.size 20 ] (Elem.text "Password")
            , onChange = \newPassword -> LoginMsg <| UpdateLoginForm { loginForm | password = newPassword }
            , show = False
            }
        , serverResponseBox
        , ElemInput.button
            [ ElemFont.size 30
            , Elem.centerX
            , Elem.padding 20
            , ElemBorder.rounded 10
            , ElemBg.color Style.colourLightGreen
            ]
            { onPress = Just <| LoginMsg SendLoginRequest
            , label = Elem.text "Login"
            }
        , Elem.row
            [ Elem.centerX ]
            [ Elem.text "Don't have an account?  "
            , ElemInput.button
                [ ElemFont.size 18
                , ElemFont.bold
                , Elem.padding 10
                , ElemBg.color Style.colourBlue
                , ElemBorder.rounded 5
                ]
                { onPress = Just <| LoginMsg GotoSignUp
                , label = Elem.text "SignUp"
                }
            ]
        ]


signUpView : SignUpForm -> Elem.Element Msg
signUpView signUpForm =
    let
        serverResponseBox =
            case signUpForm.serverResponse of
                "" ->
                    Elem.text ""

                _ ->
                    Elem.el
                        [ Elem.centerX
                        , Elem.width Elem.shrink
                        , Elem.height Elem.shrink
                        ]
                    <|
                        Elem.el
                            [ Elem.paddingXY 10 10
                            , ElemBg.color <| Elem.rgb 0.55 0 0
                            , ElemBorder.rounded 5
                            ]
                        <|
                            Elem.text signUpForm.serverResponse
    in
    Elem.column
        [ Elem.centerX
        , Elem.spacing 30
        ]
        [ ElemInput.username
            [ ElemBg.color Style.inputFieldBgColour
            ]
            { text = signUpForm.username
            , placeholder = Nothing
            , label = ElemInput.labelAbove [ ElemFont.size 20 ] (Elem.text "Username")
            , onChange = \newUsername -> SignUpMsg <| UpdateSignUpForm { signUpForm | username = newUsername }
            }
        , ElemInput.email
            [ ElemBg.color Style.inputFieldBgColour
            ]
            { text = signUpForm.email
            , placeholder = Nothing
            , label = ElemInput.labelAbove [ ElemFont.size 20 ] (Elem.text "Email")
            , onChange = \newEmail -> SignUpMsg <| UpdateSignUpForm { signUpForm | email = newEmail }
            }
        , ElemInput.newPassword
            [ ElemBg.color Style.inputFieldBgColour
            ]
            { text = signUpForm.password
            , placeholder = Nothing
            , label = ElemInput.labelAbove [ ElemFont.size 20 ] (Elem.text "New Password")
            , onChange = \newPassword -> SignUpMsg <| UpdateSignUpForm { signUpForm | password = newPassword }
            , show = False
            }
        , serverResponseBox
        , ElemInput.button
            [ ElemFont.size 30
            , Elem.centerX
            , Elem.padding 20
            , ElemBorder.rounded 10
            , ElemBg.color Style.colourLightGreen
            ]
            { onPress = Just <| SignUpMsg SendSignUpRequest
            , label = Elem.text "SignUp"
            }
        , Elem.row
            [ Elem.centerX ]
            [ Elem.text "Already have an account?  "
            , ElemInput.button
                [ ElemFont.size 18
                , ElemFont.bold
                , Elem.padding 10
                , ElemBg.color Style.colourBlue
                , ElemBorder.rounded 5
                ]
                { onPress = Just <| SignUpMsg GotoLogin
                , label = Elem.text "Login"
                }
            ]
        ]
