#!/bin/bash
# Linux Server Setup
# This version works with Ubuntu 20.04

export DEBIAN_FRONTEND=noninteractive

export TX=Pacific/Auckland

apt update
apt install -y wget curl python3 python3-pip

# mirrors.txt automatically returns mirrors in your GeoIP country
mirror=$(curl "http://mirrors.ubuntu.com/mirrors.txt" | sort -R | head -1)
pip3 install apt-mirror-updater
apt-mirror-updater -c "${mirror}"
apt-get update

# existing packages
apt-get install -y apt-transport-https software-properties-common 

readonly normal=$(printf '\033[0m')
readonly bold=$(printf '\033[1m')
readonly faint=$(printf '\033[2m')
readonly underline=$(printf '\033[4m')
readonly negative=$(printf '\033[7m')
readonly red=$(printf '\033[31m')
readonly green=$(printf '\033[32m')
readonly orange=$(printf '\033[33m')
readonly blue=$(printf '\033[34m')
readonly yellow=$(printf '\033[93m')
readonly white=$(printf '\033[39m')

function error()
{
  local msg=${1}
  echo "[${bold}${red}FAIL${normal}] ${msg}" >&2
}


function section()
{
  local msg=${1}
  echo "[${bold}${green}STARTING${normal}] ${msg}" >&2
}

function step() {
  $* 
  local return_code="$?"
  return $return_code
}

function die() {
    error "$1"
    exit 1
}


function pre_run() { 
  
  DEBIAN_FRONTEND=noninteractive apt install -y tzdata 
  mkdir initlog

}

# General nice to have packages
function nice_packages() {
  section "NICE TO HAVE PACKAGES"
  packages="jq mosh tmux screen fail2ban zsh iperf3 htop pandoc fonts-inconsolata fonts-open-sans fonts-roboto imagemagick iotop vim"
  apt-get install -y ${packages}
}

# Desktop System
function desktop_packages() {
  section "DESKTOP PACKAGES"
  packages="libreoffice openscad blender gparted krita firefox"
  apt-get install -y ${packages}
}


function node_packages() {
  section "NODE"
  curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
  apt-get install -y gcc g++ make
  apt-get install -y nodejs
}


function r() {
  section "R"
  export TZ="Pacific/Auckland"
  export DEBIAN_FRONTEND=noninteractive
  apt update -qq
  pre_run
  # install two helper packages we need
  apt install -y --no-install-recommends software-properties-common dirmngr wget
  # add the signing key (by Michael Rutter) for these repos
  # To verify key, run gpg --show-keys /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc 
  # Fingerprint: 298A3A825C0D65DFD57CBB651716619E084DAB9
  wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
  # add the R 4.0 repo from CRAN -- adjust 'focal' to 'groovy' or 'bionic' as needed
  add-apt-repository "deb https://cloud.r-project.org/bin/linux/ubuntu $(lsb_release -cs)-cran40/"
  apt install -y --no-install-recommends r-base

  R --version 
}

function r_packages() { 
  section "R PACKAGES"
  apt install -y --no-install-recommends software-properties-common dirmngr wget
  add-apt-repository -y ppa:c2d4u.team/c2d4u4.0+
  apt install -y r-cran-tidyverse r-cran-shiny
}

function rstudio_server() { 
  section "RSTUDIO SERVER"
  RSTUDIO_VERSION=2021.09.0-351
  apt update -qq 
  apt install gdebi-core wget
  wget https://download2.rstudio.org/server/bionic/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb
  packages=$(gdebi -q --apt-line rstudio-server-${RSTUDIO_VERSION}-amd64.deb)
  apt install -y ${packages}
  dpkg -i rstudio-server-${RSTUDIO_VERSION}-amd64.deb 
} 

function shiny_server() { 
  section "SHINY SERVER"
  SHINY_VERSION=1.5.16.958
  apt-get install -y gdebi-core
  wget https://download3.rstudio.org/ubuntu-14.04/x86_64/shiny-server-${SHINY_VERSION}-amd64.deb
  packages=$(gdebi -q --apt-line shiny-server-${SHINY_VERSION}-amd64.deb)
  apt install -y ${packages}
  dpkg -i shiny-server-${SHINY_VERSION}-amd64.deb
}

function zerotier() { 
  section "ZEROTIER"
  export TZ="Pacific/Auckland"
  export DEBIAN_FRONTEND=noninteractive
  apt-get update -qq 
  apt-get install -y curl software-properties-common
  curl -s https://install.zerotier.com | bash
}

function geospatial_packages() {
  section "GEOSPATIAL PACKAGES"
  # Install GEOSPATIAL Packages
  ## List of Ubuntu packages to install
  packages="gdal-bin spatialite-bin libgdal-dev virtualenv rasterio fiona grass libproj-dev libudunits2-dev"
  # Install Packages
  apt-get install -y ${packages}

  ## pip geo packages install
  pip3 install wheel rasterstats

  ## R Install some basic packages
  Rscript -e "install.packages(c('rgdal'), repos='https://cran.rstudio.com', type='source'))"
  Rscript -e "install.packages(c('maps','ggmap','maptools', repos='https://cran.rstudio.com'))"
  Rscript -e "install.packages(c('RColorBrewer', 'sf', 'plyr','reshape2', 'raster', repos='https://cran.rstudio.com'))"
}

function python_packages() {
  section "PYTHON PACKAGES"
  ## Install Python development packages
  packages="virtualenvwrapper python3 python3-setuptools"
  apt-get install -y ${packages}

}

function docker_install() {
  section "DOCKER"
  apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -
  apt-key fingerprint 0EBFCD88
  add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
   apt-get update
   apt-get install -y docker-ce docker-ce-cli containerd.io
   usermod -aG docker $USER
}


function install_zsh() { 
  section "ZSH"

  apt-get install -y zsh 
  curl  https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh > /tmp/ohmy_zsh.sh
  sh /tmp/ohmy_zsh.sh --unattended

}

step pre_run || die "Pre run has failed" 
step nice_packages || die "Nice to have packages failed"
step r || die "R packages failed"
step r_packages || die "R packages failed"
step rstudio_server || die "RStudio Server Failed"
step shiny_server || die "Shiny Server Failed" 
step geospatial_packages || die "Geospatial packages failed"
step python_packages || die "Python installation failed"
step node_packages || die "Node installation failed" 
step docker_install || die "Docker installation failed" 
step borg_backup || die "Borg Backup install failed"
step install_zsh || die "ZSH install failed"
# Create User Account and passwordless sudo

# Lock down SSHD if installed (ie not in a docker container) 

# SSH Keys
