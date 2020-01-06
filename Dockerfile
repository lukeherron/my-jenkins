# How to build:
#   DOCKER_BUILDKIT=1 docker build --build-arg GID=$(getent group docker | cut -d: -f3) --tag jenkins .
FROM jenkins4eval/jenkins:2.212-slim-arm

ARG GID
ARG JENKINS_USER
ENV JENKINS_USER ${JENKINS_USER:-admin}
ENV JAVA_OPTS -Djenkins.install.runSetupWizard=false

# We will want jenkins jobs to access the docker daemon, but we don't need the daemon in the image as it will be mounted from the host system, so we will
# just grab the latest binary and ignore the rest
USER root
RUN DOCKER_VERSION=$(curl --silent "https://api.github.com/repos/docker/docker-ce/releases/latest" | grep -Po '"name": "\K.*?(?=")') \
    && curl -fsSL https://download.docker.com/linux/static/stable/armhf/docker-$DOCKER_VERSION.tgz | tar zxvf - --strip 1 -C /usr/local/bin docker/docker

# Ran into some problems if jenkins user was not in the docker group and the docker group GID did not match the GID of the host group
RUN groupadd -g ${GID} docker && usermod -aG docker jenkins

USER jenkins
COPY plugins.txt $REF/plugins.txt
COPY jenkins.yaml /var/jenkins_home/jenkins.yaml
RUN /usr/local/bin/install-plugins.sh < $REF/plugins.txt