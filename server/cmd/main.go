package main

import (
	"github.com/go-chi/chi"
	"github.com/masseelch/cartograph"
	"github.com/rs/cors"
	"log"
	"net/http"
)

func main() {
	hub := cartograph.NewHub()
	go hub.Run()

	r := chi.NewRouter()
	r.Use(
		cors.AllowAll().Handler,
	)

	r.Get("/reboot", func(w http.ResponseWriter, r *http.Request) {
		hub.Clear()
	})

	r.HandleFunc("/{nickname:.+}", func(w http.ResponseWriter, r *http.Request) {
		cartograph.ServeWs(hub, w, r)
	})


	err := http.ListenAndServe(":8888", r)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
