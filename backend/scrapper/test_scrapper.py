import pytest
from scrapper import Scrapper


@pytest.mark.slow
def test_scrapper_known_id(tmp_path):
    # ID 404 is a known plan with data
    output = str(tmp_path / "scrapper.json")
    s = Scrapper(output=output)
    s.scrapper(404)
    assert s.stats["success"] == 1
    assert len(s.results) > 0


@pytest.mark.slow
def test_scrapper_invalid_id(tmp_path):
    # ID 1 does not exist — page never loads the grid, expect interaction failure
    output = str(tmp_path / "scrapper.json")
    s = Scrapper(output=output)
    s.scrapper(1)
    assert s.stats["interaction_fail"] == 1
    assert s.stats["success"] == 0
