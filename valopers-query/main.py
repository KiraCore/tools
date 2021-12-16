import json
import re

from urllib.request import Request
from urllib.request import urlopen
from certifi import where
from ssl import create_default_context, Purpose

class Testnet:
    def __init__(self,url) -> None:
        self.url=url
        self.name = re.search(r"\btestnet-[0-9]+\b", self.url).group()
        self.context = create_default_context(purpose=Purpose.SERVER_AUTH, cafile=where())
        self.resp = Testnet.conn(self.url)
        self.waiting = len(self.resp["waiting"])
        self.produced = len([addr['address'] for addr in self.resp['validators'] if addr['produced_blocks_counter'] != '' and addr['produced_blocks_counter'] !='0'])
        self.claimed = len([addr['address'] for addr in self.resp['validators']])
    
    @staticmethod
    def conn(url):
        context = create_default_context(purpose=Purpose.SERVER_AUTH, cafile=where())
        req = Request(url)
        return json.loads(urlopen(req, context=context).read().decode("utf-8"))


    def write(self, option):
        if option == "all":
            self._write_all()
        if option == "waiting":
            self._write_waiting()
        if option == "produced":
            self._write_produced()
        if option == "claimed":
            pass
    
    def _write_all(self):
        self._write_waiting(name="all")
        self._write_claimed(mode="a",name="all")
        self._write_waiting()
        self._write_claimed()
        self._write_produced()
    
    def stats(self):
        template = (
            f"\n\rName:\t\t{self.name}\n"
            f"Produced:\t{self.produced}\n"
            f"Claimed:\t{self.claimed}\n"
            f"Waiting:\t{self.waiting}\n"
            f"Total:\t\t{self.waiting + self.claimed}"
        )
        print(template)

    def _write_waiting(self, mode="w", name="waiting"):
        with open(f"{self.name}_{name}.txt",f"{mode}") as f:
            for addr in self.resp["waiting"]:
                f.writelines([f"{addr}\n"])

    def _write_produced(self, mode="w"):
        with open(f"{self.name}_produced.txt",f"{mode}") as f:
            for addr in self.resp["validators"]:
                if addr["produced_blocks_counter"] != "" and addr["produced_blocks_counter"] !="0":
                    f.writelines([f"{addr['address']}\n"])
    
    def _write_claimed(self, mode="w", name="claimed"):
        with open(f"{self.name}_{name}.txt",f"{mode}") as f:
            for addr in self.resp["validators"]:
                f.writelines([f"{addr['address']}\n"])

        

def main():
    testnets = [f"https://raw.githubusercontent.com/KiraCore/testnet/main/testnet-{i}/valopers.json" for i in range(1,7)]

    for testnet in testnets:
        t = Testnet(testnet)
        t.write("all")
        t.stats()

if __name__ == "__main__":
    main()