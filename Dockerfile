###############################################################################
FROM golang:1.13 as sops

RUN apt-get install --yes \
    make \
    git

WORKDIR $GOPATH/github.com/mozilla/sops
RUN git clone --depth 1 --branch v3.7.1 https://github.com/mozilla/sops.git $GOPATH/github.com/mozilla/sops
RUN make install

###############################################################################
FROM argoproj/argocd:v2.2.2

# Switch to root user to perform installation
USER root

# Install common dependencies
RUN apt-get update && \
    apt-get install -y \
        curl \
        wget \
        sudo \
        python3-pip \
        make

# Install awscli
RUN pip3 install awscli

# Install Helm 3.6.3
COPY install-helm3.sh .
RUN ./install-helm3.sh --no-sudo --version v3.7.2

# Copy sops built binary
COPY --from=sops /go/bin/sops /usr/local/bin

# Setup AWS CodeCommit Git credential helper
RUN git config --system credential.helper '!f() { HOME=/home/argocd aws codecommit credential-helper $@ ; }; f'
RUN git config --system credential.UseHttpPath true

# Switch back to argocd user
USER argocd

# Install Helm Secrets
RUN helm plugin install https://github.com/rocketspacer/helm-secrets

# Setup default AWS region
RUN aws configure set region ap-southeast-1
RUN aws configure set output json
