#!/bin/bash

set -euxo pipefail

if [[ $DB_IS_DRIVER = "TRUE" ]]; then
  sudo apt-get update
  sudo dpkg --purge rstudio-server # in case open source version is installed.
  sudo apt-get install -y gdebi-core alien

  ## Install updated version of R
  R_VERSION_ALT=4.2.1
  sudo apt-get update -qq && \
    curl -O https://cdn.rstudio.com/r/ubuntu-2004/pkgs/r-${R_VERSION_ALT}_1_amd64.deb && \
    DEBIAN_FRONTEND=noninteractive gdebi --non-interactive r-${R_VERSION_ALT}_1_amd64.deb && \
    rm -f ./r-${R_VERSION_ALT}_1_amd64.deb \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*\

  ## Installing RStudio Workbench
  cd /tmp

  # You can find new releases at https://rstudio.com/products/rstudio/download-commercial/debian-ubuntu/.
  curl -O https://s3.amazonaws.com/rstudio-ide-build/server/bionic/amd64/rstudio-workbench-2022.12.0-daily-283.pro1-amd64.deb
  sudo gdebi --non-interactive rstudio-workbench-2022.12.0-daily-283.pro1-amd64.deb

  # VS Code
  # sudo rstudio-server install-vs-code /opt/code-server --extensions-dir=/opt/code-server/extensions
  # sudo rstudio-server install-vs-code-ext -d /opt/code-server

  # Jupyter
  JUPYTER_VERSION=3.8.10
  sudo curl -O https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh && \
    bash Miniconda3-latest-Linux-x86_64.sh -bp /opt/python/jupyter && \
    /opt/python/jupyter/bin/conda install -y python==${JUPYTER_VERSION} && \
    rm -rf Miniconda3-latest-Linux-x86_64.sh && \
    /opt/python/jupyter/bin/pip install \
    jupyter \
    jupyterlab \
    rsp_jupyter \
    rsconnect_jupyter \
    workbench_jupyterlab && \
    /opt/python/jupyter/bin/jupyter kernelspec remove python3 -f && \
    /opt/python/jupyter/bin/pip uninstall -y ipykernel && \
    ln -s /opt/python/jupyter/bin/jupyter /usr/local/bin/jupyter
  
  # RSW / RSC Notebook Extensions
  sudo /opt/python/jupyter/bin/jupyter-nbextension install --sys-prefix --py rsp_jupyter && \
    /opt/python/jupyter/bin/jupyter-nbextension enable --sys-prefix --py rsp_jupyter && \
    /opt/python/jupyter/bin/jupyter-nbextension install --sys-prefix --py rsconnect_jupyter && \
    /opt/python/jupyter/bin/jupyter-nbextension enable --sys-prefix --py rsconnect_jupyter && \
    /opt/python/jupyter/bin/jupyter-serverextension enable --sys-prefix --py rsconnect_jupyter

  # launcher.conf
  echo """
  [server]
  address=localhost
  port=5559
  admin-group=rstudio-server
  server-user=rstudio-server
  authorization-enabled=1
  thread-pool-size=4
  enable-debug-logging=1

  [cluster]
  name=Local
  type=Local
  """ > /etc/rstudio/launcher.conf

  # launcher.local.conf
  echo """
  server-user=rstudio-server
  unprivileged=1
  enable-debug-logging=1
  """ > /etc/rstudio/launcher.local.conf

  # vscode.conf
  echo """
  exe=/opt/code-server/bin/code-server
  enabled=1
  default-session-cluster=Local
  args=--verbose
  """ > /etc/rstudio/vscode.conf

  # jupyter.conf
  echo """
  jupyter-exe=/opt/python/jupyter/bin/jupyter
  notebooks-enabled=1
  labs-enabled=1
  default-session-cluster=Local
  """ > /etc/rstudio/jupyter.conf

  # rserver.conf
  echo """
  launcher-address=127.0.0.1
  launcher-port=5559
  launcher-sessions-enabled=1
  launcher-default-cluster=Local
  launcher-sessions-callback-address=http://127.0.0.1:8787
  launcher-sessions-callback-verify-ssl-certs=0
  auth-minimum-user-id=500
  server-user=rstudio-server
  """ > /etc/rstudio/rserver.conf

  ## Configuring authentication
  sudo echo 'admin-enabled=1' >> /etc/rstudio/rserver.conf
  sudo echo 'export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' >> /etc/rstudio/rsession-profile

  # Session configurations
  sudo echo 'session-rprofile-on-resume-default=1' >> /etc/rstudio/rsession.conf
  sudo echo 'allow-terminal-websockets=0' >> /etc/rstudio/rsession.conf

  # Restart RStudio services
  sudo rstudio-server restart || true
  sudo rstudio-launcher restart || true
fi