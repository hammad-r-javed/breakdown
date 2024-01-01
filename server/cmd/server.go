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
	"github.com/gorilla/sessions"
)

type LoginCred struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

type ServerCtx struct {
	address string
	staticContentDir string
	cookieStore *sessions.CookieStore
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

	// TEMP
	key := []byte("super-secret-key")
	store := sessions.NewCookieStore(key)

	// TODO - load from config file
	ctx := ServerCtx{"127.0.0.1:8000", "client/out", store, db}
	return &ctx, nil
}

func StartServer(serverCtx *ServerCtx) {
	fs := http.FileServer(http.Dir(serverCtx.staticContentDir))
	http.Handle("/static/", http.StripPrefix("/static/", fs))
	http.HandleFunc("/", ApplyMiddlewares(rootPage(serverCtx, "login.html"), CheckAuth(serverCtx), AllowedMethods(http.MethodGet)))
	http.HandleFunc("/api/login", ApplyMiddlewares(loginAuth(serverCtx), AllowedMethods(http.MethodPost)))

	log.Println("Starting web server at ", serverCtx.address)
	http.ListenAndServe(serverCtx.address, nil)
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
		body, err := io.ReadAll(r.Body)
		if err != nil {
			fmt.Println(err)
			w.WriteHeader(http.StatusInternalServerError)
			fmt.Fprintf(w, "Sorry, something went wrong!!")
			return
		}

		var creds LoginCred
		err = json.Unmarshal([]byte(body), &creds)
		if err != nil {
			w.WriteHeader(http.StatusBadRequest)
			fmt.Fprintf(w, "Error, Cannot deserialise json data")
			return
		}
		// TODO - carry out credential verification + update session data accordingly
		fmt.Fprintf(w, "Username = '%s'\nPassword = '%s'\n", creds.Username, creds.Password)

	}
}

func rootPage(s *ServerCtx, p string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.URL.Path != "/" {
			w.WriteHeader(404)
			// TODO - add custom 404 static page
			fmt.Fprintf(w, "404 Sorry we can't find the page you're looking for :(")
			return
		}
		t, _ := template.ParseFiles(s.staticContentDir + "/" + p)
		t.Execute(w, nil)
	}
}

func returnPage(s *ServerCtx, p string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		t, _ := template.ParseFiles(s.staticContentDir + "/" + p)
		t.Execute(w, nil)
	}
}
