package main

import (
	"log"
	"time"
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
	email string
	sessionID string
	authExpiration int
}

type DataBase interface {
	init() error
	getUsers() ([]User, error)
	isSessionAuthed(string) (bool, error)
	credsExist(string, string) (int, error)
	startUserSession(int, string) error
	usernameExists(username string) (bool, error)
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
		err := rows.Scan(&user.id, &user.username, &user.password, &user.sessionID, &user.authExpiration);
		if err != nil {
			return nil, err
		}
		userArr = append(userArr, user)
	}

	return userArr, nil
}

func (ctx *SqliteDB) isSessionAuthed(sessionId string) (bool, error) {
	tStamp := time.Now().Unix()
	rows, queryErr:= ctx.dbCtx.Query("SELECT user_id FROM users WHERE session_id=? AND auth_expiration>?", sessionId, tStamp)
	if queryErr != nil {
		wrappedErr := errors.Join(queryErr, errors.New("isSessionAuthed() -> Unable to query sqlite3 db!"))
		return false, wrappedErr
	}

	userId := 0
	authedArr := make([]int, 0)
	for rows.Next() {
		scanErr := rows.Scan(&userId)
		if scanErr != nil {
			wrappedErr := errors.Join(scanErr, errors.New("isSessionAuthed() -> Unable to query sqlite3 db!"))
			return false, wrappedErr
		}
		authedArr = append(authedArr, userId)
	}
	if len(authedArr) == 0 {
		return false, nil
	}
	return true, nil
}

func (ctx *SqliteDB) credsExist(username string, password string) (int, error) {
	rows, queryErr:= ctx.dbCtx.Query("SELECT user_id FROM users WHERE username=? AND password=?", username, password)
	if queryErr != nil {
		wrappedErr := errors.Join(queryErr, errors.New("credsExist() -> Unable to query sqlite3 db!"))
		return -1, wrappedErr
	}

	userId := 0
	authedArr := make([]int, 0)
	for rows.Next() {
		scanErr := rows.Scan(&userId)
		if scanErr != nil {
			wrappedErr := errors.Join(scanErr, errors.New("credsExist() -> Unable to query sqlite3 db!"))
			return -1, wrappedErr
		}
		authedArr = append(authedArr, userId)
	}
	if len(authedArr) == 0 {
		return -1, nil
	}
	return authedArr[0], nil
}

func (ctx *SqliteDB) startUserSession(userId int, sessionId string) error {
	newAuthExpiration := time.Now().Unix() + 1800 // auth valid for 30 mins
	_, queryErr:= ctx.dbCtx.Exec("UPDATE users SET auth_expiration=?, session_id=? WHERE user_id=?", newAuthExpiration, sessionId, userId)
	if queryErr != nil {
		wrappedErr := errors.Join(queryErr, errors.New("startUserSession() -> Unable to query sqlite3 db!"))
		return wrappedErr
	}
	return nil
}

func (ctx *SqliteDB) usernameExists(username string) (bool, error) {
	rows, queryErr:= ctx.dbCtx.Query("SELECT user_id FROM users WHERE username=?", username)
	if queryErr != nil {
		wrappedErr := errors.Join(queryErr, errors.New("usernameExist() -> Unable to query sqlite3 db!"))
		return false, wrappedErr
	}

	userId := 0
	foundUsers := make([]int, 0)
	for rows.Next() {
		scanErr := rows.Scan(&userId)
		if scanErr != nil {
			wrappedErr := errors.Join(scanErr, errors.New("credsExist() -> Unable to scan sqlite3 query result!"))
			return false, wrappedErr
		}
		foundUsers = append(foundUsers, userId)
	}
	if len(foundUsers) == 0 {
		return false, nil
	}

	log.Printf("List of users found = ", foundUsers)
	return true, nil
}

