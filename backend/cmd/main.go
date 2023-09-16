package main

import (
	// "fmt"
	"net/http"
	"html/template"
)

func loadServerConf() map[string]string {
	// TEMP config
	conf := make(map[string]string)
	conf["address"] = "127.0.0.1:8000"
	conf["static_content_dir"] = "client/out"
	return conf
}

var conf map[string]string = loadServerConf()

func main() {	
	fs := http.FileServer(http.Dir(conf["static_content_dir"]))
	
	http.Handle("/static/", http.StripPrefix("/static/", fs))
	http.HandleFunc("/", loginPage)
	http.HandleFunc("/login", loginPage)

	http.ListenAndServe(conf["address"], nil)
}

func loginPage(w http.ResponseWriter, r *http.Request) {
	t, _ := template.ParseFiles(conf["static_content_dir"] + "/login.html")
	t.Execute(w, nil)
}
