#!/bin/bash

# find our public ip
export PUBLIC_IP=$(curl -4 ifconfig.io)
export PRIVATE_SUBNET=172.31.0.0
export PRIVATE_NETMASK=255.255.0.0


# Set up the CA directory
make-cadir ~/openvpn-ca
cd ~/openvpn-ca

# Update vars
echo "set_var EASYRSA_REQ_COUNTRY    \"${KEY_COUNTRY}\"" >> vars
echo "set_var EASYRSA_REQ_PROVINCE   \"${KEY_PROVINCE}\"" >> vars
echo "set_var EASYRSA_REQ_CITY       \"${KEY_CITY}\"" >> vars
echo "set_var EASYRSA_REQ_ORG        \"${KEY_ORG}\"" >> vars
echo "set_var EASYRSA_REQ_EMAIL      \"${KEY_EMAIL}\"" >> vars
echo "set_var EASYRSA_REQ_OU         \"${KEY_OU}\"" >> vars
echo "set_var EASYRSA_ALGO         \"ec\"" >> vars
echo "set_var EASYRSA_DIGEST         \"sha512\"" >> vars

# Build the Certificate Authority
./easyrsa init-pki
yes "" | ./easyrsa build-ca nopass

# Create the server certificate
yes "" | ./easyrsa gen-req server nopass
cp pki/private/server.key /etc/openvpn/server/
cp pki/private/ca.key /etc/openvpn/server/
cp pki/ca.crt /etc/openvpn/server/

# Sign the certificate request
yes "yes" | ./easyrsa sign-req server server
yes "yes" | cp pki/issued/server.crt /etc/openvpn/server/

# Generate an extra shared secret key
openvpn --genkey secret pki/ta.key
cp pki/ta.key /etc/openvpn/server/

# Copy the sample config to the OpenVPN directory
#cp /usr/share/doc/openvpn/examples/sample-config-files/server.conf /etc/openvpn/server/server.conf

# Adjust the OpenVPN configuration
sed -i "s/tls-auth ta.key 0/tls-crypt ta.key/" /etc/openvpn/server/server.conf
sed -i "s/cipher AES-256-CBC/cipher AES-256-GCM\nauth SHA256/" /etc/openvpn/server/server.conf
sed -i "s/dh dh2048.pem/;dh dh2048.pem\ndh none/" /etc/openvpn/server/server.conf
sed -i "s/;user nobody/user nobody/" /etc/openvpn/server/server.conf
sed -i "s/;group nobody/group nogroup/" /etc/openvpn/server/server.conf

# disable split-tunneling (all traffic 0.0.0.0 from clients will come to this vpn-gw )
echo "push \"route ${PRIVATE_SUBNET} ${PRIVATE_NETMASK}\"" >> /etc/openvpn/server/server.conf
echo "push \"redirect-gateway def1 bypass-dhcp\"" >> /etc/openvpn/server/server.conf
echo "push \"dhcp-option DNS 8.8.8.8\"" >> /etc/openvpn/server/server.conf

# Allow IP forwarding
sed -i "s/#net.ipv4.ip_forward/net.ipv4.ip_forward/" /etc/sysctl.conf
sysctl -p

# Firewall configuration
sed -i "s/# rules.before/# rules.before\n# START OPENVPN RULES\n# NAT table rules\n*nat\n:POSTROUTING ACCEPT [0:0]\n-A POSTROUTING -s 10.8.0.0\/8 -o ${VPNDEVICE} -j MASQUERADE\nCOMMIT\n# END OPENVPN RULES/" /etc/ufw/before.rules
sed -i "s/DEFAULT_FORWARD_POLICY=\"DROP\"/DEFAULT_FORWARD_POLICY=\"ACCEPT\"/" /etc/default/ufw
ufw allow 1194/udp
ufw allow 8888/tcp
ufw allow OpenSSH
ufw disable
yes "y" | ufw enable

# Creating the Client Configuration Infrastructure
mkdir -p ~/client-configs/keys
chmod -R 700 ~/client-configs
mkdir -p ~/client-configs/files
cp /usr/share/doc/openvpn/examples/sample-config-files/client.conf ~/client-configs/base.conf
sed -i "s/remote my-server-1 1194/remote ${PUBLIC_IP} 1194/" ~/client-configs/base.conf
sed -i "s/;user nobody/user nobody/" ~/client-configs/base.conf
sed -i "s/;group nobody/group nogroup/" ~/client-configs/base.conf
sed -i "s/ca ca.crt/;ca ca.crt/" ~/client-configs/base.conf
sed -i "s/cert client.crt/;cert client.crt/" ~/client-configs/base.conf
sed -i "s/key client.key/;key client.key/" ~/client-configs/base.conf
sed -i "s/tls-auth ta.key 1/;tls-auth ta.key 1/" ~/client-configs/base.conf
sed -i "s/cipher AES-256-CBC/cipher AES-256-GCM/" ~/client-configs/base.conf
echo "auth SHA256" >> ~/client-configs/base.conf
echo "key-direction 1" >> ~/client-configs/base.conf
echo ";script-security 2" >> ~/client-configs/base.conf
echo ";up /etc/openvpn/update-resolv-conf" >> ~/client-configs/base.conf
echo ";down /etc/openvpn/update-resolv-conf" >> ~/client-configs/base.conf
echo ";script-security 2" >> ~/client-configs/base.conf
echo ";up /etc/openvpn/update-systemd-resolved" >> ~/client-configs/base.conf
echo ";down /etc/openvpn/update-systemd-resolved" >> ~/client-configs/base.conf
echo ";down-pre" >> ~/client-configs/base.conf
echo ";dhcp-option DOMAIN-ROUTE ." >> ~/client-configs/base.conf


declare -a users=("chen" "kiril")

for name in ${users[@]}; do
  # add user 'user'
  cd ~/openvpn-ca/
#  name=user
  yes "" | ./easyrsa gen-req ${name} nopass
  cp pki/private/${name}.key ~/client-configs/keys/
  yes "yes" | ./easyrsa sign-req client ${name}
  cp /root/openvpn-ca/pki/issued/${name}.crt ~/client-configs/keys/
  cp /etc/openvpn/server/ta.key ~/client-configs/keys/
  cp /etc/openvpn/server/ca.crt ~/client-configs/keys/

  # make config for user 'user'
  KEY_DIR=~/client-configs/keys
  OUTPUT_DIR=~/client-configs/files
  BASE_CONFIG=~/client-configs/base.conf

  cat ${BASE_CONFIG} \
      <(echo -e '<ca>') \
      ${KEY_DIR}/ca.crt \
      <(echo -e '</ca>\n<cert>') \
      ${KEY_DIR}/${name}.crt \
      <(echo -e '</cert>\n<key>') \
      ${KEY_DIR}/${name}.key \
      <(echo -e '</key>\n<tls-crypt>') \
      ${KEY_DIR}/ta.key \
      <(echo -e '</tls-crypt>') \
      > ${OUTPUT_DIR}/${name}.ovpn

  echo "creating openvpn client config for ${name} ..."
  #cp ${OUTPUT_DIR}/${name}.ovpn /app/webserver/client.conf
  cp ${OUTPUT_DIR}/${name}.ovpn /app/webserver/${name}.ovpn


done







cd /app/webserver
python3 webserver.py 2>&1 &
echo "download openvpn client config at: http://${PUBLIC_IP}:8888/client.conf"
sleep 3s

# Start and enable the OpenVPN service
echo "starting vpn server"
cd /etc/openvpn/server
/usr/sbin/openvpn \
  --status ~/openvpn-ca/openvpn-status.log \
  --status-version 2 \
  --suppress-timestamps \
  --config /etc/openvpn/server/server.conf

