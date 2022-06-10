package types

const (
	IpfsApiVersion = "v0.0.1"

	// Pinata v1 constants
	BASE_URL     = "https://api.pinata.cloud"
	PINFILE      = "/pinning/pinFileToIPFS"   // Pin file/directory
	PINBYHASH    = "/pinning/pinByHash"       // Pin by CID hash
	UNPIN        = "/pinning/unpin"           // Delete pinned data
	METADATA_URL = "/pinning/hashMetadata"    // Can be used to store additional data or to change existing one
	PINNEDDATA   = "/data/pinList"            // Enpoint to retrive data by hash
	TESTAUTH     = "/data/testAuthentication" // Auth test
)
