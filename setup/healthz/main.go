package main

import (
	"log"
	"net/http"
)

/*
 * 作者:张晓明 时间:2019/1/11
 */

func main() {
	http.HandleFunc("/healthz", func(writer http.ResponseWriter, request *http.Request) {
		writer.Write([]byte("ok"))
		return
	})
	log.Fatal(http.ListenAndServe(":8080", nil))
}
