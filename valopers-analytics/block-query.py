
import asyncio
from unittest import result
import aiohttp

import logging
import time

import json

from ssl import create_default_context, Purpose
from certifi import where
from itertools import tee
from urllib.request import Request, urlopen

def last_block():
    url = "https://testnet-rpc.kira.network/api/status"
    context = create_default_context(purpose=Purpose.SERVER_AUTH, cafile=where())
    req = Request(url)
    resp = json.loads(urlopen(req, context=context).read().decode("utf-8"))
    return int(resp["interx_info"]["latest_block_height"])

def block_range(first_block, last_block, limit=50000):
    blocks = [block for block in range(first_block, last_block, limit)]
    if last_block!=blocks[-1]: blocks.append(last_block)
    a,b=tee(blocks)
    next(b, None)
    block_range= [interval for interval in zip(a, b)]
    return block_range

async def fetch(session, url):
    async with session.get(url) as response:
        if response.status != 200:
            response.raise_for_status()

        resp = await response.json()
        signers = [d["validator_address"] for d in resp["block"]["last_commit"]["signatures"] if d["validator_address"] != ""]
        validators = len(resp["block"]["last_commit"]["signatures"])
        #print(f'Current block: {resp["block"]["header"]["height"]}')

    return {
        "chain-id":resp["block"]["header"]["chain_id"],
        "height":resp["block"]["header"]["height"],
        "time":resp["block"]["header"]["time"],
        "validators":validators,
        "not signed:":str(int(validators)-int(len(signers))),
        "signatures": signers
        }
    

async def fetch_all(session, urls):
    tasks = []
    for url in urls:
        task = asyncio.create_task(fetch(session, url))
        tasks.append(task)
    return await asyncio.gather(*tasks)

async def main():

    logging.basicConfig(filename='block-query.log',level=logging.DEBUG)
    for i in block_range(920529,last_block(),limit=1000):
        logging.info(f"Fetching data from blocks {i[0]}..{i[1]}")
        t1_start = time.perf_counter()
        urls = [f"https://testnet-rpc.kira.network/api/blocks/{b}" for b in range(i[0],i[1])]
        timeout = aiohttp.ClientTimeout(total=0)
        async with aiohttp.ClientSession(timeout=timeout) as session:
            result = await fetch_all(session, urls)
        with open(f"blocks/blocks_{i[0]}_{i[1]}", "w") as f:
            json.dump(result,f)
        logging.info(f"Blocks {i[0]}..{i[1]} fetched in {time.perf_counter()-t1_start}")
"""
    urls = [f"https://testnet-rpc.kira.network/api/blocks/{b}" for b in range(920529,last_block())]
    timeout = aiohttp.ClientTimeout(total=0)
    async with aiohttp.ClientSession(timeout=timeout) as session:
        result = await fetch_all(session, urls)
    with open(f"blocks.json", "w") as f:
            json.dump(result,f)
 """   
    #t1_stop=time.perf_counter()
    #print(f"DONE in {t1_stop - t1_start} sec")

if __name__ =="__main__":
    asyncio.run(main())