Standard-CI GPG-based secrets
=============================

The Standard-CI GPG-based secrets system is meant to allow users of the system
to provide secret data for use by the system in a secure way.

The secrets system allows CI system users to store secret data in encrypted
files in their own Git repositories so that it is readable only by the CI
system. The CI system then decrypts the data at runtime and makes it available
to the user-provided build/test scripts.

Providing secrets to the CI system
----------------------------------
To provide some secret data for use by the CI system, one needs to encrypt the
original data and then store it in the project's Git repo with a `*.gpg`
extension.

To encrypt the secret data the following should be done:

1. If this is the first time a file is encrypted on a particular computer, the
   encryption key needs to be imported. This is done with the following command:

        gpg --keyserver hkp://keys.gnupg.net --recv-key $KEY_ID

    Where `$KEY_ID` is the key identifier associated with the CI system that
    would decrypt the file. For the oVirt CI system that would be `16B8B554`, so
    the command for importing the key for oVirt CI is:

        gpg --keyserver hkp://keys.gnupg.net --recv-key 16B8B554

    See below for a table of knows CI system keys.

2. To encrypt a file the following command is used:

        gpg -r $SYSTEM_ADDRESS -e some_secret.txt

    Where `$SYSTEM_ADDRESS` is the email address associated with the CI system's
    encryption key. For the oVirt CI system the address would be
    `jenkins@ovirt.org`, therefore the encryption command would be:

        gpg -r jenkins@ovirt.org -e some_secret.txt

    The command would generate a new file with the same name as the unencrypted
    file but with the `*.gpg` extension. The encrypted file should be committed
    to the project's git repository.

    **Please make sure to never commit the unencrypted file to Git, doing so
    will break the secrecy of the whole CI system.** Its a good idea to specify
    the names of the unencrypted files in the `.gitignore` file.

At runtime, the CI system would automatically decrypt any `*.gpg` files it finds
in the project Git repository and make them available with the same names with
the `*.gpg` extension removed. If the system finds files it cannot decrypt, they
would be ignored.

It is possible to encrypt files with multiple keys for use by multiple different
systems and users. This is done by importing all the public keys for the
relevant systems and users then specifying the `-r` option multiple time with
different addresses on the `gpg -e` command line.

Table of CI system keys
-----------------------

System                   | Email address             | Key ID
------------------------ | ------------------------- | --------
oVirt CI Jenkins         | jenkins@ovirt.org         | 16B8B554
oVirt CI Staging Jenkins | jenkins-staging@ovirt.org | 2B4C1A6C

Setting up the CI system's key pair
-----------------------------------
Following are instructions on how to perform the initial setup of an encryption
key pair for use by the CI system. This should only be performed once by the CI
infra team when setting up a new CI system instance.

1. Create an empty temporary directory to store the new keys:

        GNUPGHOME="$(mktemp -d)"
        export GNUPGHOME

    Storing the directory path in `GNUPGHOME` make the following commands use it
    implicitly. Alternatively, the `--homedir` option can be used.

2. Generate a key pair with the following command:

        gpg --gen-key

    The command will ask few questions about which key type to create and for
    whom. Please select strong encryption settings, and provide an email address
    that will be easy for the system's users to remember or figure out, because
    they need to provide it when encrypting secrets (It does not need to be an
    actual Email address though). In order to enable the CI system to access the
    key, when asked for the passphrase for the key, please provide an empty one
    despite repeated warning from the tool.

    To see the key that was created the following command can be used:

        gpg -K

    Please note the key ID shown by this command, it is needed for the next
    command.

3. Push the public key to a key server with the following command:

        gpg --keyserver hkp://keys.gnupg.net --send-keys $KEY_ID

    Where `$KEY_ID` is the 8-character key Id you can see in the output of the
    `-K` command (On the line that starts with `sec`, after the `/` character).

    You can search for the key you just pushed by going to http://keys.gnupg.net
    and searching for it in the web UI. If the key cannot be found, you might
    need to wait a while for all the key servers to sync with each other. If
    you're impatient, you can upload the key manually via the web UI, by
    exporting it with the following command:

        gpg --armor --export $KEY_ID

4. Export the private key to a text file:

        PKEY_TEMP="$(mktemp)"
        gpg --armor --export-secret-keys --output "$PKEY_TEMP"

    Confirm the question about overriding the temp file if it pops up.

5. Push the private key to Kubernetes as a secret with the following
   command. Note that the secret name and internal file name are currently
   hard-coded in the system.

        oc create secret generic ci-keyring \
            --from-file=ci-secret-keys.txt="$PKEY_TEMP"

6. Remove all local copies of the secret key and other temporary files, so the
   key does not fall into the wrong hands by mistake:

        rm -rfv "$PKEY_TEMP" "$GNUPGHOME"
        export -n GNUPGHOME
        unset GNUPGHOME PKEY_TEMP

7. Make the key identifier known to the CI system's users. They need to know
   what it is in order to import the key to their computers and encrypt files.
   For publicly available systems such as oVirt's CI system, this could be done
   by updating this document.

Decrypting encrypted files
--------------------------
Decryption of the encrypted files requires access to the CI system's private
key. It is done automatically by the CI system. The way to do it is described
here for documentation purposes.

To decrypt files one must first import the secret key into a preferably empty
GPG home directory:

    GNUPGHOME="$(mktemp -d)"
    export GNUPGHOME
    gpg --import "/path/to/ci-secret-keys.txt"

Once the key is imported, decrypting files is done simply by passing the names
of encrypted files to the `gpg` command. For example:

    gpg _some_secret.txt.gpg
