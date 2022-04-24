# valet-sh (un)installer

[![Build Status](https://github.com/valet-sh/install/actions/workflows/build.yml/badge.svg)](https://github.com/valet-sh/install/actions/workflows/build.yml)

## Install valet-sh

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/valet-sh/install/master/install.sh)
```


At the moment valet.sh on Apple m1 requires rosetta2:
```bash
/usr/sbin/softwareupdate --install-rosetta --agree-to-license
arch -x86_64 bash <(curl -fsSL https://raw.githubusercontent.com/valet-sh/install/master/install.sh)
```



## Uninstall valet-sh

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/valet-sh/install/master/uninstall.sh)
```
