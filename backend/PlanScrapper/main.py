from mapper import Mapper
from scrapper import Scrapper

mapper = Mapper
mapper.run(minID=300, maxID=400, output="flows.json")

Scrapper().run(max_workers=5)