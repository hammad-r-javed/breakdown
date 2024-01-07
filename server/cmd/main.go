package main

import (
	"log"
	"errors"
)

func main() {
	serverCtx, err := NewServerCtx()
	if err != nil {
		log.Fatal(errors.Join(err, errors.New("Unable to build server context")))
	}
	StartServer(serverCtx)
}
