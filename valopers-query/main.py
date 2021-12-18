import sys
from testnet import Testnet   

def main():
    if sys.argv:
        for arg in sys.argv[1:]:
            cli = Testnet(arg)
            cli.write("all")
            cli.stats()
    else:
        testnets = [f"https://raw.githubusercontent.com/KiraCore/testnet/main/testnet-{i}/valopers.json" for i in range(1,7)]
        for testnet in testnets:       
            t = Testnet(testnet)
            t.write("all")
            t.stats()


if __name__ == "__main__":
    main()