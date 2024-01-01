package main

import (
	"fmt"
	// "time"
	"net/http"
	// "github.com/google/uuid"
	// "html/template"
	// "github.com/gorilla/sessions"
)

func CheckAuth(serverCtx *ServerCtx) Middleware {
	return func(f http.HandlerFunc) http.HandlerFunc {
		return func(w http.ResponseWriter, r *http.Request) {
			session, err := serverCtx.cookieStore.Get(r, "session-cookie")
			if err != nil {
				http.Error(w, err.Error(), http.StatusInternalServerError)
				fmt.Println("Unable to get session obj!");
				return
			}
			auth, ok := session.Values["authenticated"].(bool)
			if (!ok || !auth) && r.URL.Path != "/" {
				http.Redirect(w, r, "/", http.StatusFound)
				return
			}
			f(w, r)
		}
	}
}

