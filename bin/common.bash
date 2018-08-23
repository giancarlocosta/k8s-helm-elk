#!/usr/bin/env bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

function commaSepStringToSpaceList() {
  local commaSeparatedList=$1;
  echo $commaSeparatedList | sed "s/,/ /g"
}

function setKubectlVersion() {
  local version="${KUBERNETES_VERSION:-$1}"
  [[ -z "$version" ]] && version="1.10.4"
  if ! [[ -f "/usr/local/bin/kubectl${version}" ]]; then
    echo "Downloading kubectl version ${version}"
    if [[ "$(uname)" == "Darwin" ]]; then
      curl -LO https://storage.googleapis.com/kubernetes-release/release/v${version}/bin/darwin/amd64/kubectl
    else
      curl -LO https://storage.googleapis.com/kubernetes-release/release/v${version}/bin/linux/amd64/kubectl
    fi
    chmod +x ./kubectl
    mv ./kubectl /usr/local/bin/kubectl${version}
  fi
  echo "Setting kubectl version to ${version}"
  ln -f -s /usr/local/bin/kubectl${version} /usr/local/bin/kubectl
}

function setHelmVersion() {
  local version="${HELM_VERSION:-$1}"
  [[ -z "$version" ]] && version="2.9.0"
  if ! [[ -f "/usr/local/bin/helm${version}" ]]; then
    echo "Downloading helm version ${version}"
    if [[ "$(uname)" == "Darwin" ]]; then
      url="https://storage.googleapis.com/kubernetes-helm/helm-v${version}-darwin-amd64.tar.gz"
    else
      url="https://storage.googleapis.com/kubernetes-helm/helm-v${version}-linux-amd64.tar.gz"
    fi
    tmpDir="/tmp/helm-binary$version"
    rm -rf "/tmp/helm-binary$version"/*; mkdir -p $tmpDir;
    curl "$url" | tar xz -C $tmpDir --strip-components=1
    chmod +x $tmpDir/helm
    mv "$tmpDir/helm" "/usr/local/bin/helm$version"
  fi
  echo "Setting helm version to $version"
  ln -f -s /usr/local/bin/helm$version /usr/local/bin/helm
}

# Check that required env vars  exists (non empty strings)
function checkRequiredVariables() {
  local required_list="${1}"
  for v in ${required_list}
  do
    :
    if [[ -z "${!v}" ]]; then
      echo
      echo "ERROR: Variable $v is not defined."
      echo "All of following variables must be defined: ${required_list}"
      exit 1
    else
      echo "$v: ${!v}"
    fi
  done
}

function require() {
  local requirements=${@}
  local missing=false
  local utility=$(basename $(caller | rev | cut -f1 -d' ' | rev))
  for requirement in ${requirements[@]}; do
    if ! (builtin command -V "${requirement}" > /dev/null 2>&1); then
      printf "${utility}: missing dependency: can't find ${requirement}\n" 1>&2
      missing=true
    fi
  done
  ${missing} && exit 1
  return 0
}

# https://gist.github.com/davejamesmiller/1965569
function ask() {
  # https://djm.me/ask
  local prompt default reply

  while true; do

    if [ "${2:-}" = "Y" ]; then
      prompt="Y/n"
      default=Y
    elif [ "${2:-}" = "N" ]; then
      prompt="y/N"
      default=N
    else
      prompt="y/n"
      default=
    fi

    # Ask the question (not using "read -p" as it uses stderr not stdout)
    echo
    echo -e -n "$1 [$prompt] "

    # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
    read reply </dev/tty

    # Default?
    if [ -z "$reply" ]; then
      reply=$default
    fi

    # Check if the reply is valid
    case "$reply" in
      Y*|y*) return 0 ;;
      N*|n*) return 1 ;;
    esac

  done
}

function confirm() {
  # https://djm.me/ask
  local prompt=$1; local expectedReply=$2; local reply;

  # Ask the question (not using "read -p" as it uses stderr not stdout)
  echo; echo -e -n "$prompt "

  # Read the answer (use /dev/tty in case stdin is redirected from somewhere else)
  read reply </dev/tty

  # Default?
  if ! [[ "$expectedReply" == "$reply" ]]; then return 1; else return 0; fi
}

function abort() {
  echo -e '\n--- Aborting ---\n';
  exit 1;
}

function msgExit() {
  echo
  echo -e "$1";
  echo
  exit 1
}

function header() {
  echo
  echo "***********************************************************************"
  echo -e "$1";
  echo "***********************************************************************"
  echo
}
