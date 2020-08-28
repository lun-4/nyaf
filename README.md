# nyaf

nyaf (nya firewall), a ufw-like frontend for npf

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
