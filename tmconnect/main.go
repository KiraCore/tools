package main

import (
	"fmt"
	"net"
	"os"
	"strconv"
	"time"

	"github.com/spf13/cobra"
	"github.com/tendermint/tendermint/crypto"
	"github.com/tendermint/tendermint/libs/protoio"
	"github.com/tendermint/tendermint/p2p"
	"github.com/tendermint/tendermint/p2p/conn"
	tmp2p "github.com/tendermint/tendermint/proto/tendermint/p2p"
)

var (
	address        string
	nodeKeyPath    string
	timeout        string
	verbose        bool
	connectionTime int64
)

type response struct {
	Code   int
	Result string
}

const codeSuccess int = 0
const codeFail int = 1

func makeTimestamp() int64 {
	return time.Now().UnixNano() / int64(time.Millisecond)
}

func main() {
	// tmconnect handshake --address=<node_id@ip:port> --node_key=<path> --timeout=<seconds> --verbose=<bool>
	// tmconnect id --address=<ip:port> --node_key=<path> --timeout=<seconds> --verbose=<bool>

	var rootCmd = &cobra.Command{
		Use:   "tmconnect [sub]",
		Short: "TM Connect",
	}

	var handshakeCommand = &cobra.Command{
		Use:   "handshake [options]",
		Short: "handshake",
		Long:  "Test handshake connection",
		RunE:  cmdHandshake,
	}

	var idCommand = &cobra.Command{
		Use:   "id [options]",
		Short: "id",
		Long:  "Get node id from address",
		RunE:  cmdNodeId,
	}

	handshakeCommand.PersistentFlags().StringVarP(&address, "address", "a", "", "<ip:port> address to connect")
	handshakeCommand.PersistentFlags().StringVarP(&nodeKeyPath, "node_key", "n", "", "<path> node_key path")
	handshakeCommand.PersistentFlags().StringVarP(&timeout, "timeout", "t", "", "<seconds> timeout seconds")
	handshakeCommand.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "print the command and results as if it were a console session")

	idCommand.PersistentFlags().StringVarP(&address, "address", "a", "", "<node_id@ip:port> address to connect")
	idCommand.PersistentFlags().StringVarP(&nodeKeyPath, "node_key", "n", "", "<path> node_key path")
	idCommand.PersistentFlags().StringVarP(&timeout, "timeout", "t", "", "<seconds> timeout seconds")
	idCommand.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "print the command and results as if it were a console session")

	rootCmd.AddCommand(handshakeCommand)
	rootCmd.AddCommand(idCommand)

	rootCmd.Execute()
}

func connect(
	netAddress *p2p.NetAddress,
	nodeKeyPath string,
	timeout string,
) (p2p.NodeInfo, response) {
	// parse node_key parameter
	printVerbose("parsing node_key: " + nodeKeyPath)
	if nodeKeyPath == "" {
		return nil, response{
			Code:   codeFail,
			Result: "empty node_key option",
		}
	}

	// parse timeout parameter
	printVerbose("parsing timeout: " + timeout + " (in seconds)")
	if timeout == "" {
		return nil, response{
			Code:   codeFail,
			Result: "empty timeout option",
		}
	}

	timeoutDuration, err := time.ParseDuration(timeout + "s")

	if err != nil {
		return nil, response{
			Code:   codeFail,
			Result: "invalid timeout option",
		}
	}

	// load node_key
	printVerbose("loading node_key")
	nodeKey, err := p2p.LoadNodeKey(nodeKeyPath)
	if err != nil {
		return nil, response{
			Code:   codeFail,
			Result: "invalid node_key option",
		}
	}

	// dial to address
	printVerbose("dialing to " + address)

	startTime := makeTimestamp()
	connection, err := netAddress.DialTimeout(timeoutDuration)
	endTime := makeTimestamp()
	if endTime-startTime > connectionTime {
		connectionTime = endTime - startTime
	}

	if err != nil {
		return nil, response{
			Code:   codeFail,
			Result: "connection failed",
		}
	}
	printVerbose("dialing success")

	// create secret connection
	printVerbose("upgrading secret connection")
	startTime = makeTimestamp()
	secretConn, err := upgradeSecretConn(connection, timeoutDuration, nodeKey.PrivKey)
	endTime = makeTimestamp()
	if endTime-startTime > connectionTime {
		connectionTime = endTime - startTime
	}

	if err != nil {
		return nil, response{
			Code:   codeFail,
			Result: "secret connection failed",
		}
	}
	printVerbose("upgrading success")

	/*
		channels, err := hex.DecodeString("40202122233038606100")
		var nodeInfo p2p.NodeInfo = p2p.DefaultNodeInfo{
			ProtocolVersion: p2p.ProtocolVersion{
				P2P:   version.P2PProtocol,
				Block: version.BlockProtocol,
				App:   0,
			},
			DefaultNodeID: nodeKey.ID(),
			ListenAddr:    "tcp://0.0.0.0:26656",
			Network:       "testing",
			Version:       "",
			Channels:      channels,
			Moniker:       "testing",
			Other: p2p.DefaultNodeInfoOther{
				TxIndex:    "on",
				RPCAddress: "tcp://127.0.0.1:26657",
			},
		}
	*/

	// handshake
	printVerbose("handshaking")
	startTime = makeTimestamp()
	peerNodeInfo, err := handshake(secretConn, timeoutDuration, p2p.DefaultNodeInfo{})
	endTime = makeTimestamp()
	if endTime-startTime > connectionTime {
		connectionTime = endTime - startTime
	}

	if err != nil {
		return nil, response{
			Code:   codeFail,
			Result: "handshake failed",
		}
	}
	printVerbose("handshaking success")

	return peerNodeInfo, response{
		Code:   codeSuccess,
		Result: string(peerNodeInfo.ID()),
	}
}

func cmdHandshake(cmd *cobra.Command, args []string) error {
	// parse address to host and port
	printVerbose("parsing address: " + address)

	netAddress, err := p2p.NewNetAddressString(address)
	if err != nil {
		response{
			Code:   codeFail,
			Result: "invalid address",
		}.printResponse()
		return nil
	}

	peerNodeInfo, resp := connect(netAddress, nodeKeyPath, timeout)

	if resp.Code == codeFail {
		resp.printResponse()
		return nil
	}

	printVerbose("checking node_id: " + string(netAddress.ID) + " == " + string(peerNodeInfo.ID()))

	if peerNodeInfo.ID() != netAddress.ID {
		response{
			Code:   codeFail,
			Result: "node_id doesn't match",
		}.printResponse()
		return nil
	}

	response{
		Code:   codeSuccess,
		Result: strconv.FormatInt(connectionTime, 10),
	}.printResponse()

	return nil
}

func cmdNodeId(cmd *cobra.Command, args []string) error {
	// parse address to host and port
	printVerbose("parsing address: " + address)

	host, portStr, err := net.SplitHostPort(address)
	if err != nil {
		response{
			Code:   codeFail,
			Result: "invalid address",
		}.printResponse()

		return nil
	}
	if len(host) == 0 {
		response{
			Code:   codeFail,
			Result: "invalid host",
		}.printResponse()

		return nil
	}

	ip := net.ParseIP(host)
	if ip == nil {
		ips, err := net.LookupIP(host)
		if err != nil {
			response{
				Code:   codeFail,
				Result: "invalid ip",
			}.printResponse()

			return nil
		}
		ip = ips[0]
	}

	port, err := strconv.ParseUint(portStr, 10, 16)
	if err != nil {
		response{
			Code:   codeFail,
			Result: "invalid port",
		}.printResponse()

		return nil
	}

	// get network address from ip:port
	netAddress := p2p.NewNetAddressIPPort(ip, uint16(port))

	peerNodeInfo, resp := connect(netAddress, nodeKeyPath, timeout)

	if resp.Code == codeFail {
		resp.printResponse()
		return nil
	}

	response{
		Code:   codeFail,
		Result: string(peerNodeInfo.ID()),
	}.printResponse()
	return nil
}

func (log response) printResponse() {
	fmt.Println(log.Result)
	os.Exit(log.Code)
}

func printVerbose(text string) {
	if verbose {
		fmt.Println(text)
	}
}

// from tendermint

func upgradeSecretConn(
	c net.Conn,
	timeout time.Duration,
	privKey crypto.PrivKey,
) (*conn.SecretConnection, error) {
	if err := c.SetDeadline(time.Now().Add(timeout)); err != nil {
		return nil, err
	}

	sc, err := conn.MakeSecretConnection(c, privKey)
	if err != nil {
		return nil, err
	}

	return sc, sc.SetDeadline(time.Time{})
}

func handshake(
	c net.Conn,
	timeout time.Duration,
	nodeInfo p2p.NodeInfo,
) (p2p.NodeInfo, error) {
	if err := c.SetDeadline(time.Now().Add(timeout)); err != nil {
		return nil, err
	}

	var (
		errc = make(chan error, 2)

		pbpeerNodeInfo tmp2p.DefaultNodeInfo
		peerNodeInfo   p2p.DefaultNodeInfo
		ourNodeInfo    = nodeInfo.(p2p.DefaultNodeInfo)
	)

	go func(errc chan<- error, c net.Conn) {
		_, err := protoio.NewDelimitedWriter(c).WriteMsg(ourNodeInfo.ToProto())
		errc <- err
	}(errc, c)
	go func(errc chan<- error, c net.Conn) {
		protoReader := protoio.NewDelimitedReader(c, p2p.MaxNodeInfoSize())
		_, err := protoReader.ReadMsg(&pbpeerNodeInfo)
		errc <- err
	}(errc, c)

	for i := 0; i < cap(errc); i++ {
		err := <-errc
		if err != nil {
			return nil, err
		}
	}

	peerNodeInfo, err := p2p.DefaultNodeInfoFromToProto(&pbpeerNodeInfo)
	if err != nil {
		return nil, err
	}

	return peerNodeInfo, c.SetDeadline(time.Time{})
}
