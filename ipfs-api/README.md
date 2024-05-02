# IPFS API CLI
A command-line interface (CLI) for interacting with the IPFS API, providing functionality to pin, unpin, and manage data and metadata using the Pinata service.

## Installation
To install the CLI, clone the repository and build the project using Go.= or dowload from existing release

```
TOOLS_VERSION="v0.3.55" && rm -rfv /tmp/ipfs-api && \
 safeWget /tmp/ipfs-api.deb "https://github.com/KiraCore/tools/releases/download/$TOOLS_VERSION/ipfs-api-$(getPlatform)-$(getArch).deb" "QmeqFDLGfwoWgCy2ZEFXerVC5XW8c5xgRyhK5bLArBr2ue" && \
 dpkg-deb -x /tmp/ipfs-api.deb /tmp/ipfs-api && cp -fv "/tmp/ipfs-api/bin/ipfs-api" /usr/local/bin/ipfs-api && chmod -v 755 /usr/local/bin/ipfs-api && \
 ipfs-api version
```

## Usage
The CLI provides several subcommands to interact with the IPFS API:

```
ipfs-api [sub]
```

### Global Flags

- --verbose, -v: Toggle verbosity level. If set to true, log output will be verbose; otherwise, it will only output JSON and errors.

### Pin Command
Pin a file or folder to IPFS using the Pinata service.

```
ipfs-api pin [options] <path>
```

#### Pin Command Flags
- --key, -k: Path to your Pinata API key.
- --cid, -c: CID version. Use 0 for CIDv0 and 1 for CIDv1.
- --force, -f: Force a name change if the file/folder already exists (default: false).
- --overwrite, -o: Delete and pin the given file/folder again (default: false).
- --metadata, -m: Additional metadata, comma-separated. Example: -m=key,value,key,value.

### Pinned Command
Retrieve pinned content by its IPFS hash or metadata name using the Pinata API.

```bash
ipfs-api pinned [options] <hash_or_name>
```

#### Pinned Command Flags
- --key, -k: Path to your Pinata API key.

### Unpin Command
Unpin content from IPFS using the Pinata API.

```bash
ipfs-api unpin [options] <hash_or_name>
```

#### Unpin Command Flags
- --key, -k: Path to your Pinata API key.

### DAG Command
Interact with IPFS DAGs (Directed Acyclic Graphs).

```bash
ipfs-api dag [options] <subcommand>
```

#### DAG Command Flags

- --export, -e: Export CID to stdout.
- --version, -c: Set CAR (Content Addressed Archives) version (default: v2).
- --out, -o: Path to save the CAR file (default: ./file.car).

#### Test Command
Test the Pinata API connection.

```
ipfs-api test [options]
```

#### Test Command Flags
- --key, -k: Path to your Pinata API key.

### Contributing
To contribute to this project, please follow the standard GitHub workflow: fork the repository, create a branch for your changes, make the changes, and submit a pull request.

