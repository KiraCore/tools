## Dependencies

```
apt-get -y install upx wine python python3 python3-pip && \
 python3 -m pip install --upgrade pip &&\
 pip3 install crossenv && \
 pip3 install ECPy && \
 pip3 install pyinstaller && \
 pip3 install --upgrade pyinstaller

# Installing specific python version (optional)
cd /usr/local && \
 wget https://www.python.org/ftp/python/3.11.0/Python-3.11.0a4.tgz -O python.tgz && \
 rm -rfv ./python && tar -xvzf python.tgz && mv ./Python-3.11.0a4 ./python

./python/configure --prefix="$PWD/python/bin"
make
make clean
make install
./python --version
```