"""Testy zakresu powiadomienia o przebiegu całego pipeline'u (main.py).

Powiadomienie obejmowało wcześniej wyłącznie json2db, więc awaria mappera,
scrappera albo parsera kończyła bezobsługowy przebieg w ciszy — czyli dokładnie
te przypadki, dla których to powiadomienie w ogóle istnieje. Każdy etap ma tu
swój test, bo regresja objawia się brakiem sygnału, a nie czerwonym buildem.
"""

import os
import runpy
from unittest.mock import MagicMock, patch

import pytest

MAIN_PATH = os.path.join(os.path.dirname(__file__), "main.py")

STAGES = ["mapper", "scrapper", "parser", "json2db"]


def _run_main(failing_stage=None, caller_handles=False):
    """Odpala main.py z podmienionymi etapami.

    Zwraca (notify_discord, check_from_env, podniesiony wyjątek albo None).
    """

    def _stage(name):
        stage = MagicMock(name=name)
        if name == failing_stage:
            stage.return_value.run.side_effect = RuntimeError(f"{name} exploded")
        return stage

    notify = MagicMock(name="notify_discord")
    structure = MagicMock(name="check_from_env")

    with patch("mapper.Mapper", _stage("mapper")), \
         patch("scrapper.HttpScrapper", _stage("scrapper")), \
         patch("parser.Parser", _stage("parser")), \
         patch("json2db.json2db", _stage("json2db")), \
         patch("structure_check.structure_check.check_from_env", structure), \
         patch("notifier.notify_discord", notify), \
         patch("notifier.pipeline_stats_text", MagicMock(return_value="")), \
         patch("notifier.caller_handles_notification",
               MagicMock(return_value=caller_handles)), \
         patch("sys.argv", ["main.py"]):
        raised = None
        try:
            runpy.run_path(MAIN_PATH, run_name="__main__")
        except Exception as exc:  # noqa: BLE001 — test inspects what escaped
            raised = exc

    return notify, structure, raised


@pytest.mark.parametrize("stage", STAGES)
def test_kazdy_etap_raportuje_porazke(stage):
    """Awaria dowolnego etapu daje dokładnie jeden embed o porażce."""
    notify, _, raised = _run_main(failing_stage=stage)

    assert isinstance(raised, RuntimeError), f"{stage} powinien przerwać przebieg"
    notify.assert_called_once()
    assert notify.call_args.args[0] == "Full Pipeline"
    assert notify.call_args.kwargs["success"] is False


@pytest.mark.parametrize("stage", STAGES)
def test_porazka_nie_uruchamia_structure_check(stage):
    """Strażnik nazw nie ma czego sprawdzać, gdy przebieg padł przed załadowaniem."""
    _, structure, _ = _run_main(failing_stage=stage)

    structure.assert_not_called()


def test_udany_przebieg_raportuje_sukces_i_sprawdza_strukture():
    notify, structure, raised = _run_main()

    assert raised is None
    notify.assert_called_once()
    assert notify.call_args.kwargs["success"] is True
    structure.assert_called_once()


@pytest.mark.parametrize("stage", STAGES + [None])
def test_zewnetrzny_caller_wycisza_powiadomienie(stage):
    """Admin i MCP raportują same za siebie — main.py nie dokłada drugiego embeda."""
    notify, _, _ = _run_main(failing_stage=stage, caller_handles=True)

    notify.assert_not_called()
