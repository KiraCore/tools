// Refactoring, not used
package pinatav2

type Keys struct {
	api_key    string
	api_secret string
	jwt        string
}

type PinataApi struct {
	keys Keys
}

func (p PinataApi) AddKeys() PinataApi {
	keys := func() Keys {
		return Keys{api_key: "", api_secret: "", jwt: ""}
	}()
	return PinataApi{keys: keys}
}
