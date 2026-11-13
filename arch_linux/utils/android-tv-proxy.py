"""mitmdump add-on used by android-tv-emu.sh (unless --no-proxy).

- TLS is passed through undecrypted; its SNI hostname is logged, since the
  emulator only hands the proxy an IP. Everything else is logged in full.
- Connections to private addresses (LAN, the host's loopback) are refused
  unless the allow_lan option is set. Only literal IPs are checked; a
  hostname that resolves to a LAN address gets through.
"""

import ipaddress
import logging

from mitmproxy import ctx, tls
from mitmproxy.addonmanager import Loader
from mitmproxy.proxy import server_hooks


def load(loader: Loader) -> None:
    loader.add_option("allow_lan", bool, False, "Allow connections to private/LAN addresses.")


def server_connect(data: server_hooks.ServerConnectionHookData) -> None:
    if ctx.options.allow_lan or data.server.address is None:
        return
    host, port = data.server.address
    try:
        ip = ipaddress.ip_address(host)
    except ValueError:
        return
    if ip.is_private or ip.is_loopback or ip.is_link_local:
        logging.warning(f"BLOCKED LAN connection: {host}:{port}")
        data.server.error = "blocked by android-tv-proxy (LAN)"


def tls_clienthello(data: tls.ClientHelloData) -> None:
    data.ignore_connection = True
    addr = data.context.server.address
    dest = f"{addr[0]}:{addr[1]}" if addr else "?"
    logging.info(f"TLS passthrough: {data.client_hello.sni or '(no SNI)'} ({dest})")
