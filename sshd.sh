#!/usr/bin/env ash

# This is the main startup script for the running sshd to keep client
# tunnels.

# Settings directory
SDIR=/etc/ssh

# Directory for HOSTKEYS, create if necessary
if [ -z "$KEYS" ]; then
    KEYS=$SDIR/keys
fi
if [ ! -d $KEYS ]; then
    mkdir -p $KEYS
fi

# Generate a ed25519 server key in the keys dir, if necessary.
if [ ! -f "${KEYS}/ssh_host_ed25519_key" ]; then
    ssh-keygen -t ed25519 -f ${KEYS}/ssh_host_ed25519_key -N ""
fi

# Arrange for the config to point at the proper server keys, i.e. at the proper
# location
if [ -f "$KEYS/ssh_host_ed25519_key" ]; then
    sed -i "s;\#HostKey $SDIR/ssh_host_ed25519_key;HostKey $KEYS/ssh_host_ed25519_key;g" $SDIR/sshd_config
fi

# Allow external hosts to connect
if [ -z "$LOCAL" -o "$LOCAL" == 0 ]; then
    sed -i "s;\GatewayPorts no;GatewayPorts yes;g" $SDIR/sshd_config
    sed -i "s;\AllowTcpForwarding no;AllowTcpForwarding yes;g" $SDIR/sshd_config
    sed -i "s;\#ClientAliveInterval \d*;ClientAliveInterval 30;g" $SDIR/sshd_config
    sed -i "s;\#ClientAliveCountMax \d*;ClientAliveCountMax 99999;g" /etc/ssh//sshd_config
fi

# UsePAM so that our autossh user that has /bin/false as shell can login
sed -i "s;\#UsePAM no;UsePAM yes;g" $SDIR/sshd_config

# add proper Ciphers, Keys, etc.
echo Ciphers aes128-ctr,aes192-ctr,aes256-ctr,aes128-gcm@openssh.com,aes256-gcm@openssh.com >> $SDIR/sshd_config
echo HostKeyAlgorithms sk-ssh-ed25519-cert-v01@openssh.com,ssh-ed25519-cert-v01@openssh.com,rsa-sha2-512-cert-v01@openssh.com,rsa-sha2-256-cert-v01@openssh.com,sk-ssh-ed25519@openssh.com,ssh-ed25519,rsa-sha2-512,rsa-sha2-256 >> $SDIR/sshd_config
echo KexAlgorithms diffie-hellman-group-exchange-sha256,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512 >> $SDIR/sshd_config
echo MACs hmac-sha2-256-etm@openssh.com,hmac-sha2-512-etm@openssh.com >> $SDIR/sshd_config

# Absolute path necessary! Pass all remaining arguents to sshd. This enables to
# override some options through -o, for example.
/usr/sbin/sshd.pam -f ${SDIR}/sshd_config -D -e "$@"
