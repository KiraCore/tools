# Valopers query
Creates four files with val. addresses. Each contains all, produced, claimed or waiting addresses.

### Setup

`
sudo apt install python3
sudo pip3 install -r requirements.txt
`

### Usage

`
python3 main.py
`
By default will try to parse jsons from kira/testnet directory and write 4 files with parsed kira address.

`
python3 main.py path_to_files
`
The app accept url or absolute path to the file location.
It also accept several paths (url, local) as sequnce of argq
### Example
Input:

`
python3 main.py ~/tmp/valopers.json https://raw.githubusercontent.com/KiraCore/testnet/main/testnet-7/valopers-end.json /home/eugene/tmp/valopers.json
`
Output:

`
Name:           valopers_json
Produced:       380
Claimed:        384
Waiting:        268
Total:          652

Name:           testnet-7_valopers-end_json
Produced:       294
Claimed:        319
Waiting:        290
Total:          609
`
Files created:

`
testnet-7_valopers-end_json_produced.txt    valopers_json_claimed.txt
testnet-7_valopers-end_json_all.txt         testnet-7_valopers-end_json_waiting.txt   valopers_json_produced.txt
testnet-7_valopers-end_json_claimed.txt     valopers_json_all.txt
`
