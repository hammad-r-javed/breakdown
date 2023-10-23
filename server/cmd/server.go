package main

import (
	"fmt"
	"net/http"
	"html/template"
	"io"
	"encoding/json"
)

type LoginCreds struct {
	Username string
	Password string
}

type LoginCred struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

func StartServer(serverConf map[string]string) {
	fs := http.FileServer(http.Dir(serverConf["static_content_dir"]))
	
	http.Handle("/static/", http.StripPrefix("/static/", fs))
	http.HandleFunc("/", loginPage(serverConf))
	http.HandleFunc("/login", loginPage(serverConf))
	http.HandleFunc("/api/login", loginAuth)

	fmt.Println("Starting web server at ", serverConf["address"])
	http.ListenAndServe(serverConf["address"], nil)
}

func loginPage(serverConf map[string]string) http.HandlerFunc {
	return func (w http.ResponseWriter, r *http.Request) {
		fmt.Println("[/ || /login] request received from ", r.RemoteAddr)
		t, _ := template.ParseFiles(serverConf["static_content_dir"] + "/login.html")
		t.Execute(w, nil)
	}
}

func loginAuth (w http.ResponseWriter, r *http.Request) {
	fmt.Println("[/api/login] request received from ", r.RemoteAddr)
	if r.Method != http.MethodPost {
		w.Header().Set("Allow", "POST")
		w.WriteHeader(http.StatusMethodNotAllowed)
		fmt.Fprintf(w, "Request method '%s' not allowed for resource '/api/login' \n", r.Method)
		return
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		fmt.Println(err)
		w.WriteHeader(http.StatusInternalServerError)
		fmt.Fprintf(w, "Sorry, something went wrong internally!!")
		return
	}

	var creds LoginCred
	err = json.Unmarshal([]byte(body), &creds)
	if err != nil {
		w.WriteHeader(http.StatusBadRequest)
		fmt.Fprintf(w, "Error, Cannot deserialise json data")
		return
	}
	// TODO - placeholder code
	fmt.Fprintf(w, "Username = '%s'\nPassword = '%s'\n", creds.Username, creds.Password)

}
