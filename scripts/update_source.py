#!/usr/bin/env python3
"""Update WristPane's AltStore/FlareStore JSON from a successfully compiled IPA."""

import argparse
from datetime import datetime, timezone
import json
import os
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BUNDLE_ID = "com.soum91.wristpane"
WARNING = (
    "Unsigned WristPane iPhone IPA with an embedded Apple Watch app and complications. "
    "This feed provides downloads, not Watch installation: the iPhone app, Watch app, "
    "and Watch widget extension require separate appropriate provisioning and signing. "
    "Normal iPhone-only FlareStore certificates cannot install the Watch companion."
)


def update_feed(feed: dict, *, build: int, size: int, date: str, repository: str) -> dict:
    if build < 1 or size < 1:
        raise ValueError("Build number and IPA size must be positive")
    if repository != "soum91/wristpane":
        raise ValueError("Unexpected repository name")
    if feed.get("identifier") != "com.soum91.wristpane.source":
        raise ValueError("Unexpected source identifier")

    version = f"0.1.{build}"
    download = f"https://github.com/{repository}/releases/download/wristpane-build.{build}/WristPane-unsigned.ipa"
    entry = {
        "version": version,
        "buildVersion": str(build),
        "date": date,
        "localizedDescription": WARNING,
        "downloadURL": download,
        "size": size,
        "minOSVersion": "27.0",
    }

    apps = feed.setdefault("apps", [])
    if not apps:
        apps.append({
            "name": "WristPane",
            "bundleIdentifier": BUNDLE_ID,
            "developerName": "soum91",
            "iconURL": "https://github.com/soum91.png",
            "tintColor": "#61B9F7",
            "category": "utilities",
            "versions": [],
        })
    if len(apps) != 1 or apps[0].get("bundleIdentifier") != BUNDLE_ID:
        raise ValueError("The WristPane source must contain exactly one app")

    app = apps[0]
    old = [v for v in app.get("versions", []) if v.get("version") != version]
    old.append(entry)
    old.sort(key=lambda v: tuple(int(part) for part in v["version"].split(".")), reverse=True)
    app["versions"] = old[:12]
    app.update({
        "subtitle": "Customizable Apple Watch dashboard",
        "localizedDescription": WARNING,
        "version": version,
        "versionDate": date,
        "versionDescription": WARNING,
        "downloadURL": download,
        "size": size,
    })
    return feed


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", type=Path, default=ROOT / "source.json")
    parser.add_argument("--ipa", type=Path, default=ROOT / "build/artifacts/WristPane-unsigned.ipa")
    parser.add_argument("--build", type=int, default=int(os.environ.get("GITHUB_RUN_NUMBER", "1")))
    parser.add_argument("--repository", default=os.environ.get("GITHUB_REPOSITORY", "soum91/wristpane"))
    parser.add_argument("--date", default=datetime.now(timezone.utc).date().isoformat())
    args = parser.parse_args()

    feed = json.loads(args.source.read_text(encoding="utf-8"))
    result = update_feed(feed, build=args.build, size=args.ipa.stat().st_size, date=args.date, repository=args.repository)
    args.source.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"WristPane FlareStore source prepared for {result['apps'][0]['version']}")


if __name__ == "__main__":
    main()
