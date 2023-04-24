package pinatav2

import (
	"math/rand"
	"time"
)

// List of common browser user agents
var userAgentList = []string{
	// Windows Browsers
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.3",
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:53.0) Gecko/20100101 Firefox/53.0",
	"Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; AS; rv:11.0) like Gecko",
	"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/64.0.3282.140 Safari/537.36 Edge/17.17134",

	// Linux Browsers
	"Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:15.0) Gecko/20100101 Firefox/15.0.1",
	"Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/51.0.2704.106 Safari/537.36",

	// macOS Browsers
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.1.1 Safari/605.1.15",
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/67.0.3396.87 Safari/537.36",
	"Mozilla/5.0 (Macintosh; Intel Mac OS X 10.13; rv:61.0) Gecko/20100101 Firefox/61.0",
}

func getRandomUserAgent() string {
	rand.Seed(time.Now().UnixNano())
	return userAgentList[rand.Intn(len(userAgentList))]
}

func (h *Header) Init() {

	if h.keys.jwt != "" {

		h.header.Add("Authorization", "Bearer "+h.keys.jwt)

	} else {
		h.header.Add("pinata_api_key", h.keys.api_key)
		h.header.Add("pinata_secret_api_key", h.keys.api_secret)
	}
	h.header.Set("User-Agent", getRandomUserAgent())

	// Set other common headers
	h.header.Set("Accept", "application/json")
	h.header.Set("Accept-Language", "en-US,en;q=0.5")
	h.header.Set("Connection", "keep-alive")
}
