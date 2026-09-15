"""Guard tests for the admin panel.

The panel has no authentication whatsoever — these three checks in
`create_app().guard` are the only thing standing between a request and the
production database. Any change to them should fail loudly here first.
"""

import pytest

from admin.app import create_app


@pytest.fixture
def client(monkeypatch):
    # Blueprints reach for Supabase/env at import time in some paths; keep the
    # guard tests independent of whether real credentials are present.
    monkeypatch.setenv("ADMIN_ALLOW_TAILNET", "")
    monkeypatch.setenv("ADMIN_ALLOWED_HOSTS", "")
    app = create_app()
    app.config.update(TESTING=True)
    return app.test_client()


def _get(client, host="localhost", peer="127.0.0.1", fetch_site=None):
    headers = {"Host": host}
    if fetch_site is not None:
        headers["Sec-Fetch-Site"] = fetch_site
    return client.get("/", headers=headers, environ_overrides={"REMOTE_ADDR": peer})


# --- Host header (DNS rebinding) ------------------------------------------

@pytest.mark.parametrize("host", ["localhost", "127.0.0.1"])
def test_loopback_hosts_allowed(client, host):
    assert _get(client, host=host).status_code != 403


def test_foreign_host_rejected(client):
    assert _get(client, host="evil.example.com").status_code == 403


def test_tailnet_host_rejected_unless_allowlisted(client):
    assert _get(client, host="mac-mini-wiit1.tailab0a78.ts.net").status_code == 403


def test_allowlisted_host_accepted(monkeypatch):
    monkeypatch.setenv("ADMIN_ALLOWED_HOSTS", "mac-mini-wiit1.tailab0a78.ts.net")
    app = create_app()
    app.config.update(TESTING=True)
    resp = app.test_client().get(
        "/", headers={"Host": "mac-mini-wiit1.tailab0a78.ts.net"},
        environ_overrides={"REMOTE_ADDR": "127.0.0.1"},
    )
    assert resp.status_code != 403


def test_allowlist_does_not_become_a_wildcard(monkeypatch):
    """Naming one host must not let every other host through — that would undo
    the rebinding protection the allowlist exists to preserve."""
    monkeypatch.setenv("ADMIN_ALLOWED_HOSTS", "mac-mini-wiit1.tailab0a78.ts.net")
    app = create_app()
    app.config.update(TESTING=True)
    resp = app.test_client().get(
        "/", headers={"Host": "evil.example.com"},
        environ_overrides={"REMOTE_ADDR": "127.0.0.1"},
    )
    assert resp.status_code == 403


# --- Peer address ----------------------------------------------------------

def test_non_loopback_peer_rejected_by_default(client):
    assert _get(client, peer="100.99.241.45").status_code == 403


def test_ipv4_mapped_loopback_accepted(client):
    assert _get(client, peer="::ffff:127.0.0.1").status_code != 403


def test_tailnet_peer_accepted_when_enabled(monkeypatch):
    monkeypatch.setenv("ADMIN_ALLOW_TAILNET", "true")
    monkeypatch.setenv("ADMIN_ALLOWED_HOSTS", "100.99.241.45")
    app = create_app()
    app.config.update(TESTING=True)
    resp = app.test_client().get(
        "/", headers={"Host": "100.99.241.45"},
        environ_overrides={"REMOTE_ADDR": "100.99.241.45"},
    )
    assert resp.status_code != 403


def test_lan_peer_still_rejected_when_tailnet_enabled(monkeypatch):
    """Enabling the tailnet must not also admit the university LAN, which is
    what a plain 0.0.0.0 bind without a range check would do."""
    monkeypatch.setenv("ADMIN_ALLOW_TAILNET", "true")
    monkeypatch.setenv("ADMIN_ALLOWED_HOSTS", "100.99.241.45")
    app = create_app()
    app.config.update(TESTING=True)
    for lan_ip in ("192.168.1.50", "10.0.0.7", "172.16.4.2"):
        resp = app.test_client().get(
            "/", headers={"Host": "100.99.241.45"},
            environ_overrides={"REMOTE_ADDR": lan_ip},
        )
        assert resp.status_code == 403, f"{lan_ip} should not reach the panel"


def test_cgnat_boundaries(monkeypatch):
    """100.64.0.0/10 is 100.64.x - 100.127.x. Addresses just outside it are
    ordinary public IPs and must not be mistaken for tailnet peers."""
    monkeypatch.setenv("ADMIN_ALLOW_TAILNET", "true")
    monkeypatch.setenv("ADMIN_ALLOWED_HOSTS", "100.99.241.45")
    app = create_app()
    app.config.update(TESTING=True)

    def status(peer):
        return app.test_client().get(
            "/", headers={"Host": "100.99.241.45"},
            environ_overrides={"REMOTE_ADDR": peer},
        ).status_code

    assert status("100.64.0.1") != 403
    assert status("100.127.255.254") != 403
    assert status("100.63.255.255") == 403
    assert status("100.128.0.1") == 403


# --- Sec-Fetch-Site (CSRF) -------------------------------------------------

@pytest.mark.parametrize("value", ["same-origin", "none"])
def test_same_origin_allowed(client, value):
    assert _get(client, fetch_site=value).status_code != 403


@pytest.mark.parametrize("value", ["cross-site", "same-site"])
def test_cross_origin_rejected(client, value):
    assert _get(client, fetch_site=value).status_code == 403


def test_absent_fetch_site_allowed(client):
    """curl and other non-browsers omit it; a hostile page cannot."""
    assert _get(client, fetch_site=None).status_code != 403
