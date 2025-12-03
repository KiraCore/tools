FROM golang:1.23-alpine AS builder

ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

# Install dependencies for build
RUN apk add --no-cache git

# Copy source
COPY go.mod go.sum ./
RUN go mod download

COPY . .

# Extract version from main.go
RUN VERSION=$(grep -m 1 'Bip39GenVersion ' main.go | sed 's/.*"\(.*\)".*/\1/') && \
    echo "$VERSION" > /tmp/version.txt

# Build binary
RUN CGO_ENABLED=0 GOOS=${TARGETOS:-linux} GOARCH=${TARGETARCH:-amd64} \
    go build -ldflags="-s -w" -o /app/bip39gen ./

# Package stage - creates .deb
FROM golang:1.23-alpine AS packager

ARG TARGETPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /app

# Install nfpm and envsubst
RUN apk add --no-cache gettext && \
    go install github.com/goreleaser/nfpm/v2/cmd/nfpm@v2.41.1

# Copy binary and config from builder
COPY --from=builder /app/bip39gen /app/bip39gen
COPY --from=builder /app/nfpm.yaml /app/nfpm.yaml.template
COPY --from=builder /tmp/version.txt /tmp/version.txt

# Create .deb package with proper variable substitution
RUN VERSION=$(cat /tmp/version.txt) && \
    PLATFORM=${TARGETOS:-linux} && \
    ARCH=${TARGETARCH:-amd64} && \
    SOURCE=/app/bip39gen && \
    export VERSION PLATFORM ARCH SOURCE && \
    envsubst < /app/nfpm.yaml.template > /app/nfpm.yaml && \
    nfpm package --packager deb --target /app/bip39gen-${PLATFORM}-${ARCH}.deb

# Final output stage
FROM alpine:latest

WORKDIR /output

COPY --from=builder /app/bip39gen /output/bip39gen
COPY --from=packager /app/*.deb /output/

# Default command shows built artifacts
CMD ["ls", "-la", "/output"]
