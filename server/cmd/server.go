package main
import (
	"log"
	"errors"
	"fmt"
	"slices"
	"strings"
	"net/http"
	"html/template"
)

type LoginCred struct {
	Username string `json:"username"`
	Password string `json:"password"`
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

func StartServer(serverCtx *ServerCtx) {
	fs := http.FileServer(http.Dir(serverCtx.staticContentDir))
	http.Handle("/static/", http.StripPrefix("/static/", fs))
	http.HandleFunc("/", ApplyMiddlewares(rootPage(serverCtx, "login.html"), AllowedMethods(http.MethodGet)))

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
