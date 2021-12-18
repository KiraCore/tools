import re
import json

from urllib.request import Request, urlopen
from urllib.parse import urlparse
from urllib.error import URLError
from certifi import where
from ssl import create_default_context, Purpose

class Source:

    def __init__(self, path) -> None:
        self.path = path
        self.scheme = urlparse(path).scheme
        self.name = Source._name(self.path)
    
    def jsonObj(self):
        if self.scheme =="":
            return self._jsonFromFile()
        else:
            return self._jsonFromUrl()

    def _jsonFromUrl(self):
        context = create_default_context(purpose=Purpose.SERVER_AUTH, cafile=where())
        req = Request(self.path)
        try:
            return json.loads(urlopen(req, context=context).read().decode("utf-8"))
        except URLError:
            raise URLError("failed to connect to the given url")
        except json.JSONDecodeError:
            raise 
    
    def _jsonFromFile(self):
        try:
            with open(self.path,"r") as f:
                return json.load(f)
        except FileNotFoundError as e:
            raise FileNotFoundError("check the path to your file")

    @staticmethod
    def _name(path):
        try:
            u = re.search(r"\btestnet-[0-9]+\b", path).group()
        except AttributeError:
            u = ""
        f = path.rsplit("/",1)[-1].replace(".","_")
        if u: return f"{u}_{f}"
        else: return f
        
        

