FROM 183782844734.dkr.ecr.us-east-1.amazonaws.com/ops-utils/jenkins-agent-inbound:3206-jdk17

USER root

RUN apt update \
    && apt install -y wget \
    && apt install -y unzip \
    && apt-get install -y sudo \
    && apt-get install -y ansible \
    && apt-get install -y python3-boto

# Allow jenkins user to execute commands as root without password
RUN echo "jenkins ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    
#Install terraform
RUN wget https://releases.hashicorp.com/terraform/1.7.4/terraform_1.7.4_linux_amd64.zip \
     && unzip terraform_1.7.4_linux_amd64.zip -d /usr/local/bin \
     && rm -rf terraform_1.7.4_linux_amd64.zip \
     && chmod +x /usr/local/bin/terraform

#Install AWS CLI
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
    && unzip awscliv2.zip \
    && ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli \
    && rm -rf awscliv2.zip

USER jenkins