package main

import (
	"errors"
	"fmt"
	"net"
	"strconv"
	"strings"
	"time"

	"github.com/spf13/cobra"
	"github.com/tendermint/tendermint/crypto"
	"github.com/tendermint/tendermint/libs/protoio"
	"github.com/tendermint/tendermint/p2p"
	"github.com/tendermint/tendermint/p2p/conn"
	tmp2p "github.com/tendermint/tendermint/proto/tendermint/p2p"
)

var (
	address     string
	nodeKeyPath string
	timeout     string
	verbose     bool
)

type response struct {
	Code   uint32
	Error  error
	Result string
}

const codeSuccess uint32 = 0
const codeFail uint32 = 1

func main() {
	// tmconnect handshake --address=<node_id@ip:port> --node_key=<path> --timeout=<seconds> --verbose=<bool>

	var rootCmd = &cobra.Command{
		Use:   "tmconnect [sub]",
		Short: "TM Connect",
	}

	var handshakeCommand = &cobra.Command{
		Use:   "handshake [options]",
		Short: "Test handshake connection",
		RunE:  cmdHandshake,
	}

	handshakeCommand.PersistentFlags().StringVarP(&address, "address", "a", "", "<ip:port> address to connect")
	handshakeCommand.PersistentFlags().StringVarP(&nodeKeyPath, "node_key", "n", "", "<path> node_key path")
	handshakeCommand.PersistentFlags().StringVarP(&timeout, "timeout", "t", "", "<seconds> timeout seconds")
	handshakeCommand.PersistentFlags().BoolVarP(&verbose, "verbose", "v", false, "print the command and results as if it were a console session")

	rootCmd.AddCommand(handshakeCommand)

	rootCmd.Execute()
}

func cmdHandshake(cmd *cobra.Command, args []string) error {
	// parse address parameter
	if address == "" {
		printResponse(cmd, args, response{
			Code:  codeFail,
			Error: errors.New("empty address option"),
		})
		return nil
	}

	// parse node_key parameter
	if nodeKeyPath == "" {
		printResponse(cmd, args, response{
			Code:  codeFail,
			Error: errors.New("empty node_key option"),
		})
		return nil
	}

	// load node_key
	nodeKey, err := p2p.LoadNodeKey(nodeKeyPath)
	if err != nil {
		printResponse(cmd, args, response{
			Code:  codeFail,
			Error: err,
		})
		return err
	}

	// parse timeout parameter
	if timeout == "" {
		printResponse(cmd, args, response{
			Code:  codeFail,
			Error: errors.New("empty timeout option"),
		})
		return nil
	}

	timeoutDuration, err := time.ParseDuration(timeout + "s")

	if err != nil {
		printResponse(cmd, args, response{
			Code:  codeFail,
			Error: err,
		})
		return nil
	}

	// parse address to host and port
	host, portStr, err := net.SplitHostPort(address)
	if err != nil {
		printResponse(cmd, args, response{
			Code:  codeFail,
			Error: err,
		})
		return nil
	}
	if len(host) == 0 {
		printResponse(cmd, args, response{
			Code:  codeFail,
			Error: errors.New("invalid address"),
		})
		return nil
	}

	ip := net.ParseIP(host)
	if ip == nil {
		ips, err := net.LookupIP(host)
		if err != nil {
			printResponse(cmd, args, response{
				Code:  codeFail,
				Error: err,
			})
			return nil
		}
		ip = ips[0]
	}

	port, err := strconv.ParseUint(portStr, 10, 16)
	if err != nil {
		printResponse(cmd, args, response{
			Code:  codeFail,
			Error: err,
		})
		return nil
	}

	// get network address from ip:port
	netAddress := p2p.NewNetAddressIPPort(ip, uint16(port))

	// dial to address
	connection, err := netAddress.DialTimeout(timeoutDuration)
	if err != nil {
		printResponse(cmd, args, response{
			Code:  codeFail,
			Error: err,
		})
		return nil
	}

	// create secret connection
	secretConn, err := upgradeSecretConn(connection, timeoutDuration, nodeKey.PrivKey)
	if err != nil {
		printResponse(cmd, args, response{
			Code:  codeFail,
			Error: err,
		})
		return nil
	}

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
	peerNodeInfo, err := handshake(secretConn, timeoutDuration, p2p.DefaultNodeInfo{})
	if err != nil {
		printResponse(cmd, args, response{
			Code:  codeFail,
			Error: err,
		})
		return nil
	}

	if peerNodeInfo.ID() == "" {
		printResponse(cmd, args, response{
			Code:  codeFail,
			Error: errors.New("failed to connect"),
		})
		return nil
	}

	printResponse(cmd, args, response{
		Code:   codeSuccess,
		Result: "connected node id: " + string(peerNodeInfo.ID()),
	})

	return nil
}

func printResponse(cmd *cobra.Command, args []string, log response) {
	fmt.Println(log.Code)

	if verbose == true {
		if log.Error != nil {
			fmt.Println(">", cmd.Use, strings.Join(args, " "))
			panic(log.Error)
		} else {
			fmt.Println(log.Result)
		}
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
