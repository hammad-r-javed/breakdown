package main

import (
	"log"
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
	sessionID string
	authenticated int
	authExpiration int
}

type DataBase interface {
	init() error
	getUsers() ([]User, error)
	isSessionAuthed(string) (bool, error)
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
		err := rows.Scan(&user.id, &user.username, &user.password, &user.sessionID, &user.authenticated, &user.authExpiration);
		if err != nil {
			return nil, err
		}
		userArr = append(userArr, user)
	}

	return userArr, nil
}

func (ctx *SqliteDB) isSessionAuthed(sessionId string) (bool, error) {
	rows, queryErr:= ctx.dbCtx.Query("SELECT authenticated FROM users WHERE session_id=?", sessionId)
	if queryErr != nil {
		wrappedErr := errors.Join(queryErr, errors.New("isSessionAuthed() -> Unable to query sqlite3 db!"))
		return false, wrappedErr
	}

	raw := 0 
	authed := false
	authedArr := make([]bool, 0)
	for rows.Next() {
		scanErr := rows.Scan(&raw)
		if scanErr != nil {
			wrappedErr := errors.Join(scanErr, errors.New("isSessionAuthed() -> Unable to query sqlite3 db!"))
			return false, wrappedErr
		}
		if raw == 0 {
			authed = false
		} else {
			authed = true
		}
		authedArr = append(authedArr, authed)
	}
	log.Printf("len(authedArr) = %d\n", len(authedArr))
	if len(authedArr) == 0 {
		return false, nil
	}
	return authedArr[0], nil
}
