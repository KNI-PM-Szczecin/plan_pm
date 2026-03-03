import shutil
import pytest
from json2db import json2db

INPUT = "./output/parser.json"


@pytest.fixture
def parser_output(tmp_path):
    if not __import__("os").path.exists(INPUT):
        pytest.skip(f"{INPUT} not found — run parser first")
    shutil.copy(INPUT, tmp_path / "parser.json")
    return str(tmp_path / "parser.json")


def test_json2db_loads(parser_output):
    db = json2db(input=parser_output)
    assert db.data is not None
    assert "programs" in db.data
