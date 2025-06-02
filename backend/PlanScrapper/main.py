from mapper import Mapper
from scrapper import Scrapper

mapper = Mapper
mapper.run(minID=200, maxID=405, output="flows.json")

Scrapper().run(max_workers=5)