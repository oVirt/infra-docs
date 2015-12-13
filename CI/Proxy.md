Phoenix Lab Proxy
=============

In the [Phoenix lab] setup we have now a proxy
VM that is also serving as repository proxy for all the slaves, mainly for mock
usage but can be used as a generic proxy.


The proxy has two services to be able to provide a reliable and fast cache, the
[Squid] proxy and the repoproxy.py. The second is only used for the yum
repositories, to be able to get the failover and speed increases from the
mirrorlists but being able to properly cache the results.

  [Phoenix lab]: ../Phoenix_Lab/Overview.html
  [Squid]:http://www.squid-cache.org/


Squid
-------------

The squid proxy is configured to reply only to ips from the Phoenix lab, it has
a huge disk cache to allow caching as many files as possible.

To invalidate a cache object, you must login to the squid server and run:

```
[root@proxy ~]# squidclient -m PURGE <URL_TO_PURGE>
```

Where `<URL_TO_PURGE>` is the url you want to invalidate, you should get a 200
response if everything went well:

```
    HTTP/1.1 200 OK
    Server: squid
    Mime-Version: 1.0
    Date: Tue, 03 Feb 2015 11:59:27 GMT
    Content-Length: 0
    X-Cache: MISS from proxy.phx.ovirt.org
    X-Cache-Lookup: NONE from proxy.phx.ovirt.org:3128
    Via: 1.1 proxy.phx.ovirt.org (squid)
    Connection: close
```

Repoproxy
--------------

The repoproxy is a small python script that proxies yum repo requests to
mirrors, it's configured using the repos.yaml file (in the puppet module),
where you define each repo it's serving, and the mirrorlist to use. For
example:


    [myrepo]
    mirrorurl=http://wherever.com/mirrorlist?repo=myrepo&ver={releasever}&arch={arch}


That will allow you to transparently get a response from the first working
mirror through the proxy using the url:

    http://myproxy:5000/myrepo/21/x86_64

Where the next two path sections after the repository name are the releasever
and arch parameters you see in the mirrorlist url. That will get the mirrorlist
from the url:

    http://wherever.com/mirrorlist?repo=myrepo$ver=21&arc=x86_64

Then try each of the mirrors until finds one that responde to the requested
path (in this case, just '/') and return it. It caches the responding mirrors
so the tests will only be done once per path tops.

The logs are located at /var/log/repoproxy.log, and the files under /opt/repoproxy

Debugging the proxy
---------------------
* In order to test if the proxy is working properly, log on to one of the VMs
at phx lab and type:
```
    curl --proxy http://proxy.phx.ovirt.org:3128 \
    http://proxy.phx.ovirt.org:5000/fedora/23/x86_64/repodata/repomd.xml
```
* If there is no response, try restarting the python script via puppet.
Log in as root to proxy.phx.ovirt.org and type:
```
    kill <repoproxy.py PID>
    puppet agent --test
```
* Note that if /var/log/repoproxy.log is not updating, it does not necessarily
mean that the proxy is not working, it could be that the
results were already cached. To see the requests watch /var/log/squid/access.log.
* As a final test (and to make sure icinga will disable the notification on
next check) type:
```
/usr/lib64/nagios/plugins/check_http -f follow -H 127.0.0.1 -p 5000 -u \
/fedora-updates/23/x86_64/ -w 5 -c 10
```
Result should be something like:
```
HTTP OK: HTTP/1.1 200 OK - 6110 bytes in 0.083 second response time
|time=0.083059s;5.000000;10.000000;0.000000 size=6110B;;;0
```
