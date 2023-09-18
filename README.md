# valet-sh (un)installer

[![Build Status](https://github.com/valet-sh/install/actions/workflows/build.yml/badge.svg)](https://github.com/valet-sh/install/actions/workflows/build.yml)

## Install valet-sh

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/valet-sh/install/master/install.sh)
```


At the moment valet.sh on Apple m1 requires rosetta2:
```bash
/usr/sbin/softwareupdate --install-rosetta --agree-to-license
bash <(curl -fsSL https://raw.githubusercontent.com/valet-sh/install/master/install.sh)
```



## Uninstall valet-sh

Unfortunately there is no process to uninstall valet.sh automaically at the moment.
