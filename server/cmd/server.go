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
	http.HandleFunc("/", ApplyMiddlewares(rootPage(serverCtx), AllowedMethods(http.MethodGet)))
	http.HandleFunc("/login", ApplyMiddlewares(returnPage(serverCtx, "login.html"), AllowedMethods(http.MethodGet)))
	http.HandleFunc("/dashboard", ApplyMiddlewares(returnPage(serverCtx, "dashboard.html"), AllowedMethods(http.MethodGet)))
	http.HandleFunc("/api/login", ApplyMiddlewares(loginAuth(serverCtx), AllowedMethods(http.MethodPost)))

	log.Println("Starting web server at ", serverCtx.address)
	http.ListenAndServe(serverCtx.address, nil)
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

func rootPage(s *ServerCtx) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		logRoute(r)
		if r.URL.Path != "/" {
			w.WriteHeader(404)
			// TODO - add custom 404 static page
			fmt.Fprintf(w, "404 Sorry we can't find the page you're looking for :(")
			return
		}

		sessionId := getSessionId(r)
		if sessionId == "" {
			http.Redirect(w, r, "/login", http.StatusFound)
		} else {
			http.Redirect(w, r, "/dashboard", http.StatusFound)
		}
	}
}

func returnPage(s *ServerCtx, p string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		logRoute(r)
		t, _ := template.ParseFiles(s.staticContentDir + "/" + p)
		t.Execute(w, nil)
	}
}

func checkAuth(serverCtx *ServerCtx) Middleware {
	return func(f http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			session, err := serverCtx.cookieStore.Get(r, "session-cookie")
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				fmt.Println("Unable to get session obj!");
				return
			}
			auth, ok := session.Values["authenticated"].(bool)
			if (!ok || !auth) && r.URL.Path != "/" && r.URL.Path != "/favicon.ico" {
				http.Redirect(w, r, "/", http.StatusFound)
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
