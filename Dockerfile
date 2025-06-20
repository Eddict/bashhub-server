# Copyright © 2020 nicksherron <nsherron90@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#
#

# GitHub:       https://github.com/eddict/bashhub-server
FROM golang:1.24.4-alpine3.22 AS build

ARG VERSION
ARG GIT_COMMIT
ARG BUILD_DATE

ARG CGO=1
ENV CGO_ENABLED=${CGO}
ENV GOOS=linux
ENV GO111MODULE=on

WORKDIR /go/src/github.com/eddict/bashhub-server

COPY . /go/src/github.com/eddict/bashhub-server/

# gcc/g++ are required to build SASS libraries for extended version
RUN apk update && \
    apk add --no-cache gcc g++ musl-dev


RUN go build  -ldflags "-X github.com/eddict/bashhub-server/cmd.Version=${VERSION} -X github.com/eddict/bashhub-server/cmd.GitCommit=${GIT_COMMIT} -X github.com/eddict/bashhub-server/cmd.BuildDate=${BUILD_DATE}" -o /go/bin/bashhub-server
FROM alpine:3.22

# Update all packages to their latest versions to reduce vulnerabilities
RUN apk update && apk upgrade
# ---

FROM alpine:3.22

COPY --from=build /go/bin/bashhub-server /usr/bin/bashhub-server

# libc6-compat & libstdc++ are required for extended SASS libraries
# ca-certificates are required to fetch outside resources (like Twitter oEmbeds)
RUN apk update && \
    apk add --no-cache ca-certificates libc6-compat libstdc++ go && \
    GO111MODULE=on go install github.com/eddict/bashhub-server@latest

VOLUME /data
WORKDIR /data

# Expose port for live server
EXPOSE 8080

ENTRYPOINT ["bashhub-server"]
CMD [ "--db", "./data.db"]
