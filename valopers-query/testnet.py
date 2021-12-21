from source import Source
    
class Testnet:
    def __init__(self,path) -> None:
        self.path=Source(path)
        self.resp = self.path.jsonObj()
        self.name = self.path.name
        self.waiting = len(self.resp["waiting"])
        self.produced = len([addr['address'] for addr in self.resp['validators'] if addr['produced_blocks_counter'] != '' and addr['produced_blocks_counter'] !='0'])
        self.claimed = len([addr['address'] for addr in self.resp['validators']])

    def write(self, option):
        if option == "all":
            self._write_all()
        if option == "waiting":
            self._write_waiting()
        if option == "produced":
            self._write_produced()
        if option == "claimed":
            self._write_claimed()
    
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
            try:
                for addr in self.resp["waiting"]:
                    f.writelines([f"{addr}\n"])
            except KeyError:
                raise KeyError("failed to parse file.")


    def _write_produced(self, mode="w"):
        with open(f"{self.name}_produced.txt",f"{mode}") as f:
            try:
                for addr in self.resp["validators"]:
                    if addr["produced_blocks_counter"] != "" and addr["produced_blocks_counter"] !="0":
                        f.writelines([f"{addr['address']}\n"])
            except KeyError:
                raise KeyError("failed to parse file.")
    
    def _write_claimed(self, mode="w", name="claimed"):
        with open(f"{self.name}_{name}.txt",f"{mode}") as f:
            try:
                for addr in self.resp["validators"]:
                    f.writelines([f"{addr['address']}\n"])
            except KeyError:
                raise KeyError("failed to parse file")