## KIRA Bash Utils

The ultimate collection of various bash-shell function to make access to various system components fast and simple from the CLI level


### Local Setup
```
./bash-utils.sh utilsSetup "/var/kiraglob"
```

### Remote Setup
```
cd /tmp && rm -fv ./bash-utils.sh && \
 wget https://raw.githubusercontent.com/KiraCore/tools/latest/bash-utils/bash-utils.sh -O ./bash-utils.sh && \
 chmod -v 555 ./bash-utils.sh && ./bash-utils.sh bashUtilsSetup "/var/kiraglob"
```
