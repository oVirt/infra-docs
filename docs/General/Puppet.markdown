Puppet development tips
==============================
Creating a 'testing' environment for new puppet code:
=====================================================
1. Create a new patch in infra-puppet, assuming your branch/topic name is 'fix_puppet'
2. Push your patch into a new branch, lets assume you name it 'testing':

        git push gerrit fix_puppet:testing

3. ssh to foreman.ovirt.org and populate the new enviornment:

        su puppet-repos -c "cd /home/puppet-repos && scl enable ruby193 '/home/puppet-repos/bin/r10k deploy environment testing'"

4. In foreman import the new environment:

        https://foreman.ovirt.org/environments -> 'Import from foreman.ovirt.org'

5. Change in foreman the puppet environment to 'testing' for the host you are
    working on.

6. Run puppet on your host to see the changes:

        puppet agent --test

    for logging you can use:

        rm -rf puppetlog; puppet agent --test 2>&1 puppetlog | tee -a puppetlog


* Iterate as you need (steps 2 and 3).
* Note that if the environment already exists, you don't need step 4.
* Once done, delete the testing branch you used.
