Networking
==========

The oVirt datacenter in Phoenix has got several [internal networks](Networking.markdown)
used for various purposes. Since they are not accessible from the outside, the easiest way
to connect is via VPN. An OpenVPN service is available and served by gw02.phx.ovirt.org.

OpenVPN uses TLS to authenticate users and encrypt traffic. It works via TCP on port 443
which is permitted by most network firewalls and proxies.

Add a new user
==============

To allow access to the VPN for a new user it's necessary to generate a certificate
and sign it by the OpenVPN CA. The CSR file can be provided by the user but in this example
we'll generate a certificate and sign it immediately.

First - log in the machine which contains the oVirt OpenVPN CA.
At the moment of this writing the CA is on the PHX Gateway. 
Root access to this machine is required as well as the __CA password__ to perform signing tasks.

    $ ssh gw02.phx.ovirt.org
    $ sudo su -
    # cd /etc/openvpn/ssl/ca

The CA uses a wrapper around openssl called [easyrsa](https://github.com/OpenVPN/easy-rsa)
that is suited specifically for use with OpenVPN.

To generate a certificate and private key with no password for user _testuser_ run:

     ./easyrsa  build-client-full testuser nopass

The script will ask for the *CA password* and generate files in the following locations:

    pki/private/testuser.key - private key
    pki/issued/testuser.crt - signed certificate

Also, the CA certificate is needed by the client, it is located here:

    pki/ca.crt

OpenVPN config template
=======================

Ensure the client system has OpenVPN installed, it is provided
by the "openvpn" package on all major distibutions.

The above data can be inserted into this template and
saved as /etc/openvpn/client/ovirt.conf on the client system.


    client
    dev tun4
    proto tcp
    remote gw02.phx.ovirt.org 443
    remote 66.187.230.121 443
    resolv-retry infinite
    nobind
    persist-key
    persist-tun
    cipher AES-128-CBC
    verb 3
    <ca>
    -----BEGIN CERTIFICATE-----
    ...CA certificate goes here...
    -----END CERTIFICATE-----
    </ca>
    <cert>
    -----BEGIN CERTIFICATE-----
    ...Client certificate goes here...
    -----END CERTIFICATE-----
    </cert>
    <key>
    -----BEGIN PRIVATE KEY-----
    ...Private key goes here...
    -----END PRIVATE KEY-----
    </key>


after it is saved, enable and start the service to run permanently:

    systemctl enable openvpn-client@ovirt
    systemctl start openvpn-client@ovirt

Alternatively - import the config file via network manager to be able
to connect through the applet when needed. In this case, certificates and keys
need to be saved in a location reachable by Network Manager.

Delete a user
=============

To ensure an existing user cannot connect, the certifiate needs to be revoked by the CA.
For that, go into the CA directory as described in the user creation step and run:

    ./easyrsa revoke testuser

After performing revocation, generate a new CRL file so that OpenVPN knows about the change:

    ./easyrsa gen-crl

OpenVPN re-reads this file each time a client connects to it, so no restart is necessary.
