package main

import (
	// "fmt"
	// "log"
	// "github.com/golang-jwt/jwt/v5"
	// "github.com/mattn/go-sqlite3"
)

func loadServerConf() map[string]string {
	// TEMP config
	conf := make(map[string]string)
	conf["address"] = "127.0.0.1:8000"
	conf["static_content_dir"] = "client/out"
	return conf
}

func loadDbConf() map[string]string {
	// TEMP config
	conf := make(map[string]string)
	conf["username"] = ""
	conf["password"] = ""
	conf["address"] = "db/dev.db"
	return conf
}

func main() {
	sConf := loadServerConf()
	StartServer(sConf)
}
