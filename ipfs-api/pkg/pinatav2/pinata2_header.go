package pinatav2

func (h *Header) Init() {
	if h.keys.jwt != "" {

		h.header.Add("Authorization", "Bearer "+h.keys.jwt)

	} else {
		h.header.Add("pinata_api_key", h.keys.api_key)
		h.header.Add("pinata_secret_api_key", h.keys.api_secret)
	}
}
