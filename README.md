My nixos configurations.


Systems
=======

[frumar](https://en.wikipedia.org/wiki/Frumar)
--------

Physical server. Mostly used for files. (storage: 6 TB hdd + 256GB ssd, RAM: 8GB, 2 cores ht)

- [git hosting](./modules/gogs.nix)
- [public files](./roles/pub.nix)
- torrents
- [quassel](./roles/quassel.nix)

[pennyworth](https://en.wikipedia.org/wiki/Alfred_Pennyworth)
----------

VPS (Storage: 80GB, RAM: 1GB, 2 cores)

- [grafana](./roles/graphs.nix)
- [website](./roles/website.nix)
- [email](./roles/main.nix)
- [prosody](./roles/xmpp.nix)
- [asterisk](./roles/asterisk.nix)

[woodhouse](https://en.wikipedia.org/wiki/List_of_Archer_characters#Recurring_characters)
-----------

intel nuc connected to the tv (storage: 64GB ssd, RAM: 4GB)

- kodi
- sshfs mounts to alphonse & frumar


[ascanius](https://en.wikipedia.org/wiki/Frumar)
----------

hp elitebook 8570w (RAM: 16GB, 4 cores ht, storage: 256GB ssd + 300GB HDD)

- includes a power saving script

[jarvis](https://en.wikipedia.org/wiki/Edwin_Jarvis)
--------

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
