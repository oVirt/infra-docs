Merging identitis on Gerrit
===========================

This note documents how to handle request like the following:

    Please merge my Gerrit IDs

    Signed,
      John Shith,
      person@foo.com

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
the user to experiance the "split accounts" situation. We will move them to the
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

Since the user ID and accoutn details are chached, we need to flush the Gerrit
server cache with the following command:

    ssh gerrit.ovirt.org -p 29418 gerrit flust-caches --all

