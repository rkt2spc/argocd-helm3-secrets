FROM argoproj/argocd:v1.4.2

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

# Install Helm 3.1.2
COPY install-helm3.sh .
RUN ./install-helm3.sh --no-sudo --version v3.1.2

# Install Helm Secrets
RUN helm plugin install https://github.com/futuresimple/helm-secrets

# Switch back to argocd user
USER argocd

# Install Helm Secrets at user level
RUN helm plugin install https://github.com/futuresimple/helm-secrets

# Setup AWS CodeCommit Git credential helper
RUN git config --global credential.helper '!aws codecommit credential-helper $@'
RUN git config --global credential.UseHttpPath true

# Setup default AWS region
RUN aws configure set region ap-southeast-1
RUN aws configure set output json
