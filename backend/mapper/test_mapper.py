import pytest
from mapper import Mapper


@pytest.mark.slow
def test_check_page_valid():
    # ID 404 is a known valid plan
    mapper = Mapper()
    flow_id, name = mapper.check_page(404)
    assert flow_id == 404
    assert name is not None


@pytest.mark.slow
def test_check_page_invalid():
    # ID 0 should return no plan
    mapper = Mapper()
    flow_id, name = mapper.check_page(0)
    assert flow_id == 0
    assert name is None
