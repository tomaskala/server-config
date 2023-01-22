import argparse
import ipaddress
import logging
import re
import sys
from subprocess import run

import requests
from requests.exceptions import Timeout

LOGGER = logging.getLogger(__name__)
COMMENT = re.compile(r"\s*#.*$")
TRAILING_DOTS = re.compile(r"\.+$")
REQUEST_TIMEOUT = 10


def all_lines(source):
    with open(source, encoding="utf-8") as f:
        yield from map(str.strip, f)


def is_ip_address(string):
    try:
        ipaddress.ip_address(string)
    except ValueError:
        return False
    else:
        return True


def parse_blocklist(text):
    blocklist = []
    lines = text.lower().splitlines()

    for line in filter(None, map(lambda l: COMMENT.sub(repl="", string=l), lines)):
        parts = line.split()

        if is_ip_address(parts[0]):
            blocklist.extend([TRAILING_DOTS.sub("", part) for part in parts[1:]])
        elif len(parts) == 1:
            blocklist.append(TRAILING_DOTS.sub("", parts[0]))
        else:
            LOGGER.warning("Unexpected format of line '%s'", line)

    return blocklist


def retrieve_blocklist(sources):
    LOGGER.info("Retrieving blocklist")
    blocklist = []

    for source in all_lines(sources):
        try:
            response = requests.get(source, timeout=REQUEST_TIMEOUT)
        except Timeout:
            LOGGER.error("Timeout when retrieving source '%s'", source)
            continue

        if not response:
            LOGGER.error(
                "Got status code %d from source '%s'", response.status_code, source
            )
            continue

        LOGGER.info("Parsing source '%s'", source)
        blocklist.extend(parse_blocklist(response.text))

    return set(blocklist)


def clear_blocklist():
    LOGGER.info("Clearing blocklist")
    LOGGER.info("Obtaining current local zones")

    p = run(
        ["unbound-control", "list_local_zones"],
        bufsize=1,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )

    LOGGER.info("unbound-control stderr:\n%s", p.stderr)

    if p.returncode != 0:
        LOGGER.critical("unbound-control exitted with code %d", p.returncode)
        sys.exit(1)

    blocklist = []

    for local_zone in p.stdout.splitlines():
        parts = local_zone.split(" ")

        if len(parts) != 2:
            LOGGER.error("Unexpected format of local zone '%s'", local_zone)
            continue

        if parts[1] == "always_null":
            blocklist.append(parts[0])

    LOGGER.info("Removing current blocklist (%d domains)", len(blocklist))

    if blocklist:
        p = run(
            ["unbound-control", "local_zones_remove"],
            input="\n".join(blocklist) + "\n",
            bufsize=1,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
        LOGGER.info("unbound-control stdout:\n%s", p.stdout)
        LOGGER.info("unbound-control stderr:\n%s", p.stderr)

    if p.returncode != 0:
        LOGGER.critical("unbound-control exitted with code %d", p.returncode)
        sys.exit(1)


def load_blocklist(blocklist):
    LOGGER.info("Filling blocklist (%d domains)", len(blocklist))
    local_zones = [f"{domain}. always_null" for domain in blocklist]

    if local_zones:
        p = run(
            ["/usr/sbin/unbound-control", "local_zones"],
            input="\n".join(local_zones) + "\n",
            bufsize=1,
            capture_output=True,
            text=True,
            encoding="utf-8",
        )
        LOGGER.info("unbound-control stdout:\n%s", p.stdout)
        LOGGER.info("unbound-control stderr:\n%s", p.stderr)

    if p.returncode != 0:
        LOGGER.critical("unbound-control exitted with code %d", p.returncode)
        sys.exit(1)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-s",
        "--sources",
        required=True,
        help="File with blocklist source URLs, one per line",
    )
    parser.add_argument(
        "-w",
        "--whitelist",
        required=False,
        help="Whitelist file with one domain per line",
    )
    parser.add_argument(
        "-l",
        "--log",
        required=True,
        help="Path to the log file",
    )
    args = parser.parse_args()

    logging.basicConfig(
        filename=args.log,
        format="%(asctime)-15s %(levelname)s [%(filename)s:%(lineno)d]: %(message)s",
        datefmt="%Y-%m-%d %H:%M:%S",
        level=logging.INFO,
    )

    blocklist = retrieve_blocklist(args.sources)

    if args.whitelist is not None:
        blocklist -= set(all_lines(args.whitelist))

    clear_blocklist()
    load_blocklist(list(blocklist))


if __name__ == "__main__":
    main()
