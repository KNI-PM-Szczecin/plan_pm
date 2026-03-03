import os
import shutil
import pytest
from parser import Parser

INPUT = "./output/scrapper.json"


@pytest.fixture
def scrapper_output(tmp_path):
    if not os.path.exists(INPUT):
        pytest.skip(f"{INPUT} not found — run scrapper first")
    shutil.copy(INPUT, tmp_path / "scrapper.json")
    return str(tmp_path)


def test_parser_runs(scrapper_output):
    p = Parser(input="scrapper.json", output=scrapper_output)
    p.run()
    assert os.path.exists(os.path.join(scrapper_output, "parser.json"))
