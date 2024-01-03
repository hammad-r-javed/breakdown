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
            signUpUpdateHandler signUpMsg


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


signUpUpdateHandler : SignUpMsgT -> ( Model, Cmd msg )
signUpUpdateHandler msg =
    case msg of
        UpdateSignUpForm newForm ->
            ( SignUp newForm
            , Cmd.none
            )

        GotoLogin ->
            ( Login emptyLoginForm
            , Cmd.none
            )



-- SUBSCRIPTIONS


subscriptions : Model -> Sub msg
subscriptions model =
    Sub.none



-- VIEW


view : Model -> Html Msg
view model =
    Elem.layout
        [ ElemBg.color Style.baseBgColour
        , ElemFont.color Style.baseFontFgColor
        ]
    <|
        Elem.text "login page loaded"
