package main

import (
	// "log"
	"fmt"
	"errors"
	"database/sql"
	_ "github.com/mattn/go-sqlite3"
)

type DBConfig struct {
	dbType string
	username string
	password string
	address string
}

type User struct {
	id int
	username string
	password string
}

type DataBase interface {
	init() error
	getUsers() ([]User, error)
}

// TODO - temp config
func LoadDbConf() (*DBConfig, error) {
	conf := DBConfig{"sqlite3", "", "", "db/main.db"}
	return &conf, nil
}

func NewDataBase(dc *DBConfig) (DataBase, error) {
	if dc.dbType == "sqlite3" {
		return &SqliteDB{dc.address, nil}, nil
	}
	return nil, errors.New(fmt.Sprintf("Invalid database type -> %s", dc.dbType))
}

type SqliteDB struct {
	address string
	dbCtx *sql.DB
}

func (ctx *SqliteDB) init() error {
	db, err := sql.Open("sqlite3", ctx.address)
	if err != nil {
		wrappedErr := errors.Join(err, errors.New("Unable to init sqlite3 db"))
		return wrappedErr
	}
	ctx.dbCtx = db
	return nil
}

func (ctx *SqliteDB) getUsers() ([]User, error) {
	rows, err:= ctx.dbCtx.Query("SELECT * FROM users")
	if err != nil {
		panic(err)
	}

	user := User{}
	userArr := make([]User, 0)
	for rows.Next() {
		err := rows.Scan(&user.id, &user.username, &user.password);
		if err != nil {
			return nil, err
		}
		userArr = append(userArr, user)
	}

	return userArr, nil
}
