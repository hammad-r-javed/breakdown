package main

import (
	"fmt"
	// "log"
	"net/http"
	// "net/url"
	"html/template"
	"io/ioutil"
	"encoding/json"

	// "github.com/golang-jwt/jwt/v5"
	// "github.com/mattn/go-sqlite3"
)

var conf map[string]string = loadServerConf()

type LoginCreds struct {
	Username string
	Password string
}

type LoginCred struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

func loadServerConf() map[string]string {
	// TEMP config
	conf := make(map[string]string)
	conf["address"] = "127.0.0.1:8000"
	conf["static_content_dir"] = "client/out"
	return conf
}


func main() {
	fs := http.FileServer(http.Dir(conf["static_content_dir"]))
	
	http.Handle("/static/", http.StripPrefix("/static/", fs))
	http.HandleFunc("/", loginPage)
	http.HandleFunc("/login", loginPage)
	http.HandleFunc("/api/login", loginAuth)

	fmt.Println("Starting web server at ", conf["address"])
	http.ListenAndServe(conf["address"], nil)
}

func loginPage(w http.ResponseWriter, r *http.Request) {
	t, _ := template.ParseFiles(conf["static_content_dir"] + "/login.html")
	t.Execute(w, nil)
}

func loginAuth (w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.WriteHeader(http.StatusMethodNotAllowed)
		fmt.Fprintf(w, "Request method '%s' not allowed for resource '/api/login' \n", r.Method)
		return
	}

	body, err := ioutil.ReadAll(r.Body)
	if err != nil {
		fmt.Println(err)
	}

	// temp code below
	var creds LoginCred

	err = json.Unmarshal([]byte(body), &creds)
	if err != nil {
		fmt.Fprintf(w, "Error, Cannot deserialise json data!!")
	} else {
		fmt.Fprintf(w, "Username = '%s'\nPassword = '%s'\n", creds.Username, creds.Password)
	}
	
}
