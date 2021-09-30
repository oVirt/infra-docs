IPA
===

The FreeIPA server is hosted on [PSI Openstack](Overview.markdown) and used to manage user access
to infra servers. It is reachable at https://ipa.ovirt.org

Enrolling a system
------------------

To enable IPA authentication on a system, it needs to be enrolled into the IPA domain.
Run the following commands to enroll:

1) install the IPA client

    `yum module enable idm:client`
    `yum install ipa-client`

2) ensure that the hostname of the system is in the ovirt.org domain
3) enroll the system (you will be asked for a user/pass enter your IPA credentials)

    `ipa-client-install --server=ipa.ovirt.org --domain=ovirt.org --realm=OVIRT.ORG --mkhomedir --ntp-server=0.us.pool.ntp.org`

After running this command, the server should appear on the IPA web UI and start accepting logins.

Deleting a system
-----------------

To remove a system log in to the web UI and navigate to the "Hosts" page.
Find the host and click the "Actions" button, select "Unprovision".

Adding a user
-------------

To add a user please log in to the web UI and click the "Add" button on the "Identity > Users" page.
Fill in user details and set a temporary password.
Ask the user to log in, set the permanent password and add an SSH key that will be used to log in.

In order to allow full access add the new user to the `ovirt-infra-admins` group.

Enabling 2FA
------------

To enable dual-factor auth for a user, select the "Two factor authentication (password + OTP)" option.
The user will then be able to log in to IPA using just a password and register a 2FA token.
Once the token is registered it needs to be used to log in and perform sudo actions

Adding OTP Token
------------

To add OTP token:

1. Login into IPA server
2. Open "Profile"
3. Select "Actions" -> "Add OTP Token"
4. Change parameters of OTP Token if needed and hit "Add"

Default parameters should work in most cases.

To force usage of OTP token on a per-user basis, even if 2FA is not forced globally on IPA server,
user can enable "Two factor authentication (password + OTP)" in his Profile

Disabling a user
----------------

To disable a user, use the "Actions" button and select "Disable". This will immediately disable login.

Resetting the password
----------------------

Password reset must be performed by an admin user. To reset a password, use the "Actions" button
and select "Reset password"

