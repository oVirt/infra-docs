How to create your own PGP key
================================

Below there's a small minimal introduction on how to use gpg to manage your pgp
keys, and to encrypt and decrypt files.  

Creating the keypair
---------------------

To create your first PGP (Pretty Good Privacy) key pair, you can install the
gnupg package, that will install a suite of helpers to handle the pgp keys.
There are other alternatives, like using seahorse or other gui managers, how to
use those will be left for the reader to discover, though the concepts are
mostly common.


So to create our first pair of keys, just run:

    gpg --gen-key

That will pop up a bunch of questions, first one (for my own version, 1.4.20):

    Please select what kind of key you want:
        (1) RSA and RSA (default)
        (2) DSA and Elgamal
        (3) DSA (sign only)
        (4) RSA (sign only)
    Your selection?

The default is ok, next:

    RSA keys may be between 1024 and 4096 bits long.
    What keysize do you want? (2048)

The default is also ok, though the max is better ;) (4096)

    Requested keysize is 4096 bits
    Please specify how long the key should be valid.
            0 = key does not expire
            <n>  = key expires in n days
            <n>w = key expires in n weeks
            <n>m = key expires in n months
            <n>y = key expires in n years
    Key is valid for? (0)

You can accept the default, so it will not expire, though for security reasons
it's better to let it expire, you will be able to extend the expiration date
even if it has expired, so there's no porblem there, a 2y value for this should
be nice.

    Is this correct? (y/N) y
    You need a user ID to identify your key; the software constructs the user ID
    from the Real Name, Comment and Email Address in this form:
        "Heinrich Heine (Der Dichter) <heinrichh@duesseldorf.de>"
    
    Real name: Ni Knight
    Email address: ni@knig.ht
    Comment: Ni!
    You selected this USER-ID:
    "Ni Knight (Ni!) <ni@knig.ht>"
    
    Change (N)ame, (C)omment, (E)mail or (O)kay/(Q)uit?

So here just fill up all the info, and when you are fine with it, hit Okay (o).

    You need a Passphrase to protect your secret key.
    
    Enter passphrase:
    Repeat passphrase:

Now you have to choose a good, nice passphrase, something that you will
remember and that would be hard to guess (see https://xkcd.com/936/ ).
It will ask you to repeat the passphrase, and then it will generte your new key
pair!!! Congratulations!

    ...
    pub   4096R/DD242797 2016-05-23
          Key fingerprint = 5E7A 6E3F DF0C C3B7 0B1E  C95C BF04 B2F0 DD24 2797
    uid                  Ni Knight (Ni!) <ni@knig.ht>
    sub   4096R/54F582B8 2016-05-23


Importing/exporting the keys
-----------------------------

If you want to use your key on another laptop, or have a backup you will have
to export it as a file (right now, it's in the gpg). You can export/import your
key in ascii armored format, or binary one, up to you.


Binary mode:

    # secret/private key (don't share!!!)
    gpg --export-secret-keys ni@knig.ht > my_gpg_key.priv
    # public key, the one you should share
    gpg --export ni@knig.ht > my_gpg_key.pub

Ascii armored:

    # secret/private key (don't share!!!)
    gpg --armor --export-secret-keys ni@knig.ht > my_gpg_key.priv
    # public key, the one you should share
    gpg --armor --export ni@knig.ht > my_gpg_key.pub

Don't share you private key with anyone!! Noone needs it except for you, anyone
else only needs your public key.


Adding more identities
-----------------------
Sometimes you want to add more than one email address to the same key, to do
so, you can just run:

    gpg --edit-key ni@knig.ht

That will open up an interactive menu that will let you modify the key and the
identities associated with it. You can then use the command 'adduid' to add a
new uid to the key (you can see all the available command with the 'help'
command).


Uploading to a public pgp server
---------------------------------

In onder to share with the world you new key, one way is to publish it on one
of the pgp public servers, I'll use pgp.mit.edu, but you can use any other you
like.

Firs you'll have to get the key id of your key, it was shown on creation, but
if you don't remember:

    gpg --list-keys ni@knig.ht
    pub   4096R/DD242797 2016-05-23
    uid                  Ni Knight (Ni!) <ni@knig.ht>
    sub   4096R/54F582B8 2016-05-23

The key id is in this case **DD242797**, so let's use that and publish the key:

    gpg --keyserver pgp.mit.edu --send-keys DD242797
    gpg: sending key DD242797 to hkp server pgp.mit.edu

And voila! You can search your key now on http://pgp.mit.edu/

Revoking a key
----------------

Sometimes, for some reason (for example, if you lost your laptop somewhere) you
might want to avoid anyone from using your key, even yourself, to do so, you
can blacklist it, but be careful, as this can't be undone.

To revoke your keys, you will need to still have them, or to have created the
following revoke certificate and still have it around, if you don't have any of
those, you wont be able to revoke the key!

To generate the revoke certificate:

    gpg --gen-revoke ni@knig.ht > revoke_cert

That will create a text file with the revocation cert, I recommend having it
stored somewhere in a safe place as a fallback in case you completely lose your
key.

To make the revoke public and effectively let everyone know, just import it and
publish it:

    gpg --import revoke_cert
    gpg --keyserver pgp.mit.edu --send-keys ni@knig.ht


Retrieve other people's keys
=============================

Though the safest way to get someone elses key is personally, sometimes is
enough to get it from one of the online servers. To look for example for the
key that we just created, you can run:

    gpg --search-keys ni@knig.ht

If any keys are found, it will ask you to confirm which one if any to import,
select the one that you were looking for and from now on that key will be
locally available for you to verify and encript for.

Encrypting
===========

To encrypt a file, you can just:

    gpg --output doc.gpg --encrypt --recipient blake@cyb.org doc

That will create an encypted copy of the 'doc' file under 'doc.gpg' that only
the owner of the 'blake@cyb.org' can decrypt.


Decrypting
===========

Decrypting is as easy as:

    gpg --output doc --decrypt doc.pgp

That will decrypt the file, remember that you must have the private key that
matches the public one used to encrypt the file, or you will not be able to
decrypt it.


Other resources
=================

* GPG manual: https://www.gnupg.org/gph/en/manual.html
