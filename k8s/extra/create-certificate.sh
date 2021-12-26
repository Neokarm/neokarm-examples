#!/bin/bash
set -e

CA_HOSTNAME=""
FQDNS=""
IP_ADDRESSES=""
NOCA=false

usage () {
    echo "USAGE: $0 --hostname hostname [--hostname hostname] [--ip ip_address] [--auto-ip] path"
    echo "  path  - where to install the key & certificate to"
    echo "  [--no-ca] Do not create CA certificate"
    echo "  [--ca fqdn] CA FQDN to use"
    echo "  [-n|--fqdn fqdn] full qualified dns name/s to define in in the certificiate - can be used multiple time"
    echo "  [-i|--ip ip_address] IP Address to define in certificate - can be used multiple time"
    echo "  [--auto-ip] Add all active local IPv4 addresses to certificate - in addition to all specific IP Address given"
    echo "  [-h|--help] Usage message"
}

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        -n|--fqdn)
        if [[ x"$2" =~ x\*.* ]]
        then
          FQDNS="${FQDNS} $2"
        else
          FQDNS="${FQDNS} $2"
        fi
        shift # past argument
        shift # past value
        ;;
        --no-ca)
        NOCA=true
        shift # past argument
        ;;
        --ca)
        CA_HOSTNAME="$2"
        shift # past argument
        shift # past value
        ;;
        -i|--ip)
        IP_ADDRESSES="${IP_ADDRESSES} $2"
        shift # past argument
        shift # past value
        ;;
        --auto-ip)
        AUTO_IP="true"
        shift # past argument
        ;;
        -h|--help)
        help="true"
        shift
        ;;
        *)
        INSTALL_PATH="$1"
        shift
        ;;
    esac
done

if [ "x${help}" == "xtrue" ]
then
	usage
	exit 0
fi

if [ "x{INSTALL_PATH}" == "x" ]
then
  echo "path must be specified"
  usage
  exit 1
fi

if [ "x${FQDNS}" == "x" ]
then
  echo "At least one fqdn should be given"
	usage
	exit 0
fi

if [[ "x${CA_HOSTNAME}" == "x" && "x${NOCA}" == "xfalse" ]]
then
  echo "One of '--ca FQDN' or '--no-ca should' be used"
  usage
  exit 1
fi
if [ "x${AUTO_IP}" == "xtrue" ]
then
   IP_ADDRESSES="${IP_ADDRESSES} $(ip -4 addr  | grep "state UP" | grep "inet\b" | awk '{print $2}' | cut -d/ -f1)"
fi

if [ "x${NOCA}" == "xfalse" ]
then
  openssl genrsa -out "${INSTALL_PATH}/ca.key" 4096
  chmod 0640 "${INSTALL_PATH}/ca.key"
  openssl req -x509 -new -nodes -sha512 -days 3650 \
   -subj "/CN=${CA_HOSTNAME}" \
   -key "${INSTALL_PATH}/ca.key" \
   -out "${INSTALL_PATH}/ca.crt"
fi

cat > "${INSTALL_PATH}/v3.ext" <<-EOF
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names

[alt_names]
EOF

index=1
for HOSTNAME in ${FQDNS}
do
    if [ "x${PRIMARY_HOSTNAME}" == "x" ]
    then
      PRIMARY_HOSTNAME=${HOSTNAME}
    fi
    if [[ x"${HOSTNAME}" =~ x\*.* ]]
    then
      echo DNS.$index=${HOSTNAME}
      echo DNS.$index=${HOSTNAME} >> "${INSTALL_PATH}/v3.ext"
    else
      echo DNS.$index=${HOSTNAME}
      echo DNS.$index=${HOSTNAME} >> "${INSTALL_PATH}/v3.ext"
    fi
    index=$(( $index + 1 ))
done

index=1
for IP_ADDRESS in $IP_ADDRESSES
do
    echo IP.$index="${IP_ADDRESS}" >> "${INSTALL_PATH}/v3.ext"
    index=$(( ${index} + 1 ))
done

openssl genrsa -out "${INSTALL_PATH}/cluster.key" 4096
chmod 0640 "${INSTALL_PATH}/cluster.key"

openssl req -sha512 -new \
    -subj "/CN=${PRIMARY_HOSTNAME}" \
    -key "${INSTALL_PATH}/cluster.key" \
    -out "${INSTALL_PATH}/cluster.csr"

if [ "x${NOCA}" == "xfalse" ]
then
  openssl x509 -req -sha512 -days 3650 \
      -extfile "${INSTALL_PATH}/v3.ext" \
      -CA "${INSTALL_PATH}/ca.crt" -CAkey "${INSTALL_PATH}/ca.key" -CAcreateserial \
      -in "${INSTALL_PATH}/cluster.csr" \
      -out "${INSTALL_PATH}/cluster.crt"
else
  openssl x509 -new -nodes -req -sha512 -days 3650 \
      -extfile "${INSTALL_PATH}/v3.ext" \
      -in "${INSTALL_PATH}/cluster.csr" \
      -out "${INSTALL_PATH}/cluster.crt"
fi
