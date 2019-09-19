FROM quay.io/operator-framework/ansible-operator:v0.10.0
USER root

RUN yum -y install git && pip install jmespath yq wget
RUN yum install -y epel-release
RUN yum install -y jq

USER ${USER_UID}

COPY configmap.template ${HOME}/configmap.template
COPY generate-configmap.sh ${HOME}/generate-configmap.sh


COPY roles/ ${HOME}/roles/
COPY watches.yaml ${HOME}/watches.yaml
