# nyaf

nyaf (nya firewall), a ufw-like frontend for npf

## maybe don't use it

while starting to write this i noticed that npf is way more expressive compared
to what i'm aiming for, and even then, its inspiration, ufw, is to combat
the hell that is iptables. npf isn't iptables. trying to make an ufw-like tool
for npf is eh.

i won't keep working on it, but the wip sources will be there.

## build

```sh
zig build

# or, if you want to cross compile to netbsd from linux
zig build --target x86_64-netbsd --libc path/to/libc.txt
```

## usage

**todo actually write this, just a draft of how it might look**

```sh
# confirm that you want to have nyaf generate a /etc/npf.conf file for you
nyaf enable

nyaf deny all
nyaf allow http
nyaf allow https

nyaf list
```
