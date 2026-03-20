# Build stage
FROM golang:1.21-alpine AS builder

WORKDIR /app

# Install dependencies
RUN apk add --no-cache git gcc musl-dev

# Copy source code
COPY . .

# Download dependencies and generate go.sum
RUN go mod tidy

# Build
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -o greenbamboo .

# Final stage
FROM alpine:latest

WORKDIR /app

# Install SQLite dependencies
RUN apk add --no-cache ca-certificates

# Copy binary from builder
COPY --from=builder /app/greenbamboo .

# Create data directory
RUN mkdir -p /app/data /app/config

EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost:3000/api/v1/health || exit 1

CMD ["./greenbamboo"]
