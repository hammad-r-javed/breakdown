package main
import (
	"log"
	"io"
	"errors"
	"fmt"
	"slices"
	"strings"
	"net/http"
	"encoding/json"
	"html/template"
	"github.com/google/uuid"
)

type LoginCred struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type SignUpCred struct {
	Username string `json:"username"`
	Password string `json:"password"`
	Email string `json:"email"`
}

type ServerCtx struct {
	address string
	staticContentDir string
	db DataBase
}

type Middleware func(http.HandlerFunc) http.HandlerFunc

func NewServerCtx() (*ServerCtx, error) {
	dbConf, loadConfErr := LoadDbConf()
	if loadConfErr != nil {
		return nil, errors.Join(loadConfErr, errors.New("Unable to load database config"))
	}

	db, newDbErr := NewDataBase(dbConf)
	if newDbErr != nil {
		return nil, errors.Join(newDbErr, errors.New("Unable to create new db"))
	}

	dbInitErr := db.init()
	if dbInitErr != nil {
		return nil, errors.Join(dbInitErr, errors.New("Unable to init database!"))
	}

	// TODO - load from config file
	ctx := ServerCtx{"127.0.0.1:8000", "client/out", db}
	return &ctx, nil
}

func StartServer(s *ServerCtx) {
	fs := http.FileServer(http.Dir(s.staticContentDir))
	http.Handle("/static/", http.StripPrefix("/static/", fs))
	http.HandleFunc("/", ApplyMiddlewares(rootPage(s), checkAuth(s), AllowedMethods(http.MethodGet)))
	http.HandleFunc("/login", ApplyMiddlewares(returnPage(s, "login.html"), AllowedMethods(http.MethodGet)))
	http.HandleFunc("/dashboard", ApplyMiddlewares(returnPage(s, "dashboard.html"), checkAuth(s), AllowedMethods(http.MethodGet)))
	http.HandleFunc("/api/login", ApplyMiddlewares(loginAuth(s), AllowedMethods(http.MethodPost)))
	http.HandleFunc("/api/signup", ApplyMiddlewares(signUp(s), AllowedMethods(http.MethodPost)))

	log.Println("Starting web server at ", s.address)
	http.ListenAndServe(s.address, nil)
}

func logRoute(r *http.Request) {
	log.Printf(`[ "%s" ] Request from %s\n`, r.URL.Path, r.RemoteAddr)
}

func ApplyMiddlewares(f http.HandlerFunc, ms ...Middleware) http.HandlerFunc {
	for _, m := range ms {
		f = m(f)
	}
	return f
}

func AllowedMethods(methods ...string) Middleware {
	return func(f http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			if !slices.Contains(methods, r.Method) {
				w.Header().Set("Allow", strings.Join(methods, ", "))
				w.WriteHeader(http.StatusMethodNotAllowed)
				fmt.Fprintf(w, "Request method '%s' not allowed for resource '/api/login' \n", r.Method)
				return
			}
			f(w, r)
		}
	}
}

func loginAuth(s *ServerCtx) http.HandlerFunc {
	return func (w http.ResponseWriter, r *http.Request) {
		logRoute(r)
		body, err := io.ReadAll(r.Body)
		if err != nil {
			log.Println(err)
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "Sorry, something went wrong!!")
			return
		}

		var creds LoginCred
		err = json.Unmarshal([]byte(body), &creds)
		if err != nil {
			log.Println(err)
			w.WriteHeader(http.StatusBadRequest)
			fmt.Fprintf(w, "Error, Cannot deserialise json data")
			return
		}

		userId, credsVerificationErr := s.db.credsExist(creds.Username, creds.Password)
		if credsVerificationErr != nil {
			log.Println(credsVerificationErr)
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "Sorry, something went wrong!!")
			return
		}

		if userId == -1 {
			w.WriteHeader(http.StatusUnauthorized)
			fmt.Fprintf(w, "Invalid username or password!")
			return
		}

		sessionId := uuid.New().String()
		startSessionErr := s.db.startUserSession(userId, sessionId)
		if startSessionErr != nil {
			log.Println(startSessionErr)
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "Sorry, something went wrong!!")
			return
		}

		w.Header().Set("Set-Cookie", "sessionId=" + sessionId + "; Path=/")
		w.WriteHeader(200)
		return
	}
}

func signUp(s *ServerCtx) http.HandlerFunc {
	return func (w http.ResponseWriter, r *http.Request) {
		logRoute(r)
		body, err := io.ReadAll(r.Body)
		if err != nil {
			log.Println(err)
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "Sorry, something went wrong!!")
			return
		}

		var creds SignUpCred
		err = json.Unmarshal([]byte(body), &creds)
		if err != nil {
			log.Println(err)
			w.WriteHeader(http.StatusBadRequest)
			fmt.Fprintf(w, "Error, Cannot deserialise json data")
			return
		}
		
		creds.Username = strings.TrimSpace(creds.Username)
		creds.Password = strings.TrimSpace(creds.Password)
		creds.Email = strings.TrimSpace(creds.Email)

		if creds.Username == "" || creds.Password == "" || creds.Email == "" {
			w.WriteHeader(http.StatusBadRequest)
			fmt.Fprintf(w, "Credentials cannot be empty!")
			return
		}

		userExists, usernameVerificationErr := s.db.usernameExists(creds.Username)
		if usernameVerificationErr != nil {
			log.Println(usernameVerificationErr)
			w.WriteHeader(http.StatusBadRequest)
			fmt.Fprintf(w, "Error, cannot verify username existance")
			return
		}

		if userExists {
			w.WriteHeader(http.StatusConflict)
			fmt.Fprintf(w, "Error, username already exists!")
			return
		}

		newSessionId := uuid.New().String()
		newUser := User { username: creds.Username, email: creds.Email, password: creds.Password, sessionID: newSessionId, authExpiration: 1 }

		addNewUserErr := s.db.addUser(newUser)
		if addNewUserErr != nil {
			log.Println(addNewUserErr)
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "Sorry, something went wrong!!")
			return
		}

		w.WriteHeader(http.StatusOK) // TEMP
		fmt.Fprintf(w, "User successfully created!")
		return
	}
}

func rootPage(s *ServerCtx) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		logRoute(r)
		if r.URL.Path == "/" {
			log.Println("Redirecting to dashboard")
			http.Redirect(w, r, "/dashboard", http.StatusFound)
			return
		}
		w.WriteHeader(404)
		// TODO - add custom 404 static page
		fmt.Fprintf(w, "404 Sorry we can't find the page you're looking for :(")
		return
	}
}

func returnPage(s *ServerCtx, p string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		logRoute(r)
		t, _ := template.ParseFiles(s.staticContentDir + "/" + p)
		t.Execute(w, nil)
	}
}

func checkAuth(s *ServerCtx) Middleware {
	return func(f http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			sessionId := getSessionId(r)
			sessionAuth, authVerificationErr := s.db.isSessionAuthed(sessionId)
			if authVerificationErr != nil {
				log.Println(authVerificationErr)
				w.WriteHeader(http.StatusInternalServerError)
				fmt.Fprintf(w, "Sorry, something went wrong!!")
				return
			}
			if !sessionAuth {
				http.Redirect(w, r, "/login", http.StatusFound)
				return
			}
			f(w, r)
		}
	}
}

func getSessionId(r *http.Request) string {
	log.Printf("Getting session cookie for request from %s\n", r.RemoteAddr)
	cookies := r.Cookies()
	sessionId := ""
	for _, v := range cookies {
		if v.Name == "sessionId" {
			sessionId = v.Value
		}
	}

	return sessionId
}
