My nixos configurations.


Systems
=======

[frumar](https://en.wikipedia.org/wiki/Frumar)
--------

Physical [server](./roles/server.nix). Mostly used for files. (storage: 6 TB hdd + 256GB ssd, RAM: 8GB, 2 cores ht)

- [git hosting](./services/gogs.nix)
- [public files](./services/pub.nix)
- torrents
- [quassel](./services/quassel.nix)

[pennyworth](https://en.wikipedia.org/wiki/Alfred_Pennyworth)
----------

[Server](./roles/server.nix).
VPS (Storage: 80GB, RAM: 1GB, 2 cores)

- [grafana](./services/graphs.nix)
- [website](./services/website.nix)
- [email](./services/mail.nix)
- [prosody](./services/xmpp.nix)
- [asterisk](./services/asterisk.nix)

[woodhouse](https://en.wikipedia.org/wiki/List_of_Archer_characters#Recurring_characters)
-----------

intel nuc connected to the tv (storage: 64GB ssd, RAM: 4GB)

- kodi
- sshfs mounts to alphonse & frumar


[ascanius](https://en.wikipedia.org/wiki/Frumar)
----------

[workstation](./roles/workstation.nix).
hp elitebook 8570w (RAM: 16GB, 4 cores ht, storage: 256GB ssd + 300GB HDD)

- includes a power saving script

[jarvis](https://en.wikipedia.org/wiki/Edwin_Jarvis)
--------

[workstation](./roles/workstation.nix).
dell xps 13 (RAM: 16GB, storage: 512GB ssd, 2 cores ht)

- for now, just run powertop --auto-tune after a reboot I guess


Maintenance
===========

Generating tor keys:

```
$(nix-build packages/shallot.nix --no-out-link)/bin/shallot -f tmp ^PATTERN
head -n3 tmp
tail -n +4 tmp > keys/ssh.HOSTNAME.key
shred tmp && rm tmp

```
