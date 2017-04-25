Merging identitis on Gerrit
===========================

This note documents how to handle request like the following:

    Please merge my Gerrit IDs

    Signed,
      John Shith,
      person@foo.com

There are actually tow ways to do it:

1. A semi-automated process using a helper tool
2. Doing it manually with the Gerrit command line

Using the semi-automated process
--------------------------------

First you need to obtain the helper tool by cloning the ['jenkins'
repository][1].

To run the tool we need to "`cd`" to the root of our 'jenkins' repo clone. The
tool includes some embedded documentation that can be seen by running the
following command:

    python -m scripts.gerrit_dedup -h

You will get a help message like the following:

    usage: gerrit_dedup.py [-h] [-s SERVER] [-p PORT] {query,merge_onto} ...

    Gerrit account unifying tool

    positional arguments:
      {query,merge_onto}
	query               Query accounts for a given name
	merge_onto          Merge accounts together

    optional arguments:
      -h, --help            show this help message and exit
      -s SERVER, --server SERVER
			    Gerrit serer to connect to
      -p PORT, --port PORT  Port of gerrit server to connect to

To merge the different user identities we need to first figure out the account
IDs for those identities as well as the account ID for the account that we will
merge the identities into. We can query for the accounts of a given user by
running the following command:

    python -m scripts.gerrit_dedup query 'John Smith'

We will get output like the following:

    account_id | full_name  | registered_on | inac | ex_ids | changes | comment
    -----------+------------+---------------+------+--------+---------+--------
    1000123    | John Smith | 2011-12-21    | N    | 5      | 688     | 8927
    1000456    | John Smith | 2015-04-22    | Y    | 0      | 0       | 0
    1000789    | John Smith | 2016-03-23    | N    | 1      | 0       | 0

This output tells us a few important things:

1. 'John Smith' has 3 account IDs
2. Account ID '1000456' is inactive and does not include any external IDs
3. Account ID 1000123 is probably the main used account because it includes
   changes or comments
4. Account ID '1000789' includes an external identity. This is what is causing
   the issues for the user and it needs to be merged into account ID '1000123'

The tool actually uses an SQL 'LIKE' expression internally, so if we are not
sure that the uses spelled his full name the same way for all accounts we can do
something like:

    python -m scripts.gerrit_dedup query 'John S%'

We can now use the to tool merge account ID '1000789' into account ID '1000123':

    python -m scripts.gerrit_dedup merge_onto 1000123 1000789

Pleas note, **we specify the account to keep first!** Be careful to not do this the
other way around. Doing this the wrong way will be very hard to fix!

We can actually use his command to merge multiple accounts into the same main
one at the same time:

    python -m scripts.gerrit_dedup merge_onto 1000123 1000456 1000789

The command will merge the accounts. Once its done the issues the user is
experiencing should be resolved.

[1]: https://gerrit.ovirt.org/#/admin/projects/jenkins

Merging identities manually
---------------------------

Connect to Gerrit's DB console:

    ssh gerrit.ovirt.org -p 29418 gerrit gsql

List out the accounts for the requester:

    select account_id, full_name, registered_on, inactive,
      (select count(1) from account_external_ids e
      where e.account_id = a.account_id) as ex_ids,
      (select count(1) from changes c 
      where c.owner_account_id = a.account_id) as changes,
      (select count(1) from change_messages m
      where m.author_id = a.account_id) as comments
    from accounts a
    where full_name like 'John S%'
    order by registered_on asc;

You will get output that will look roughly like this (output tweaked a little to
fit in page):

    account_id | full_name  | registered_on | inac | ex_ids | changes | comment
    -----------+------------+---------------+------+--------+---------+--------
    1000123    | John Smith | 2011-12-21    | N    | 5      | 688     | 8927
    1000456    | John Smith | 2015-04-22    | Y    | 0      | 0       | 0
    1000789    | John Smith | 2016-03-23    | N    | 1      | 0       | 0

We can see one inactive account which is of no interest to us, and two active
accounts of which the older one holds all the changes and comments. This is the
account that we will keep.

We can see that the newer account has some external identities which are causing
the user to experience the "split accounts" situation. We will move them to the
older account:

    update account_external_ids set account_id=1000123 where account_id=1000789;

We will get something like tihs showing how many rows were updated:

    UPDATE 2; 2 ms

You can verify the change by re-running the big query from the beginning of the
document.

Now quit the DB with:

    \q

Now deactivate the unused account ID with the following command:

    ssh gerrit.ovirt.org -p 29418 gerrit set-account --inactive 1000456

Since the user ID and account details are cached, we need to flush the Gerrit
server cache with the following command:

    ssh gerrit.ovirt.org -p 29418 gerrit flust-caches --all

