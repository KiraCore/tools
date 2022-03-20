## KIRA Bash Utils

The ultimate collection of various bash-shell function to make access to various system components fast and simple from the CLI level


### Local Setup
```
./utils.sh utilsSetup ./utils.sh "/var/kiraglob"
```

### Remote Setup
```
cd /tmp && rm -fv ./utils.sh && \
 wget https://raw.githubusercontent.com/KiraCore/tools/latest/bash-utils/utils.sh -O ./utils.sh && \
 chmod -v 555 ./utils && ./utils.sh utilsSetup ./utils.sh "/var/kiraglob"
```
