# Valopers query
Creates four files with val. addresses. Each contains all, produced, claimed or waiting addresses.

### Setup

`
mkdir -p ~/tmp
`\
`
cd ~/tmp
`\
`
git clone https://github.com/KiraCore/tools.git
`\
`
sudo apt install python3
`\
`
sudo pip3 install -r requirements.txt
`

### Usage

`
python3 main.py
`\
By default will try to parse jsons from kira/testnet directory and write 4 files with parsed kira address.\

`
python3 main.py path_to_files
`\
The app accept url or absolute path to the file location.
It also accept several paths (url, local) as sequnce of args
### Example
Input:

`python3 main.py ~/tmp/valopers.json https://raw.githubusercontent.com/KiraCore/testnet/main/testnet-7/valopers-end.json`

Output:

![image](https://user-images.githubusercontent.com/70693118/146642039-56f1f3c7-0df0-4ae4-a37e-bc145362170a.png)

Files created:

![image](https://user-images.githubusercontent.com/70693118/146642110-44f49084-eadd-43e8-9b79-bcffdc821338.png)

