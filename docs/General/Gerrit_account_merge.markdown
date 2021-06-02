Merging identitis on Gerrit
===========================

This note documents how to handle request like the following:

    Please merge my Gerrit IDs

    Signed,
      John Smith,
      person@foo.com

Users and identities are separate in Gerrit and it is possible to link several identities
(Google, GitHub, etc) to a single user.

If a person who already has an account logs in using an identity that has not been linked,
Gerrit will create a new user ID and cause confusion as multiple accounts with the same name will exist.
To fix this, all external IDs need to be merged into one account and extra accounts need to be disabled.

Starting with Gerrit 2.15 user data is stored in the All-Users git repo.
To make changes to this repo, one must be a member of the Administrators group on Gerrit.

In order to merge accounts, please ask the requester which ID needs to nbe kept.
The account ID is shown on the [user settings page on gerrit](https://gerrit.ovirt.org/#/settings/)

The account with most changes/comments is usually chosen, it will likely be the one with a lower ID.

After gathering the data, clone the repo:

    git clone ssh://gerrit.ovirt.org:29418/All-Users
    cd All-Users
    git fetch origin refs/meta/external-ids:refs/meta/external-ids
    git checkout refs/meta/external-ids

To find duplicate account IDs, query the API in a browser against the user name:
https://gerrit.ovirt.org//accounts/?q=name:John

The output will look something like this:

    )]}'
    [
      {
        "_account_id": 1000123
      },
      {
        "_account_id": 1000456
      },
      {
        "_account_id": 1000789
      }
    ]

In this example, the account that needs to be kept is 1000123.
Find all identities matching all accounts :

    git grep -e 1000123 -e 1000456 -e 1000789
    11/c409969ea5ed3fb050a636603322e5d79dcd11:      accountId = 1000123
    3a/c4a1b94c06619979d992c8dff12210907ce13a:      accountId = 1000456
    aa/eff198d7d71c98572962d0ee479cbda18f87aa:      accountId = 1000456
    bc/843e189f31112a86338c567655bc33cf9a24bc:      accountId = 1000789

Each of the files found is an identity. Edit the files that need to be merged
and change theif accountId to 1000123, then commit the changes:

    git add -A
    git commit --signoff
    git push origin HEAD:refs/meta/external-ids

Deactivate the unneeded account ID with the following command:

    ssh gerrit.ovirt.org -p 29418 gerrit set-account --inactive 1000456

Since the user ID and account details are cached, we need to flush the Gerrit
server cache with the following command:

    ssh gerrit.ovirt.org -p 29418 gerrit flush-caches --all

To verify that everything works as expected please ask the user to log in to Gerrit
using both identities and ensure all of them authenticate as account 1000123.
