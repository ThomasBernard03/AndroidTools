"""Build metadata and the legacy Sparkle feed using only the Python standard library."""

import base64
import json
import os
from pathlib import Path
import plistlib
import re
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from email.utils import format_datetime
import xml.etree.ElementTree as ET

ROOT = Path(__file__).resolve().parents[1]
SPARKLE = "http://www.andymatuschak.org/xml-namespaces/sparkle"
REPOSITORY = "ThomasBernard03/AndroidTools"
PUBLIC_KEY = "z9EBcFEFrJ5Bi6oiODtO2k6fo7X61gTEKmiuG3+Qxwg="
FEED_URL = f"https://raw.githubusercontent.com/{REPOSITORY}/refs/heads/main/appcast.xml"
ET.register_namespace("sparkle", SPARKLE)


def sparkle(name):
    return f"{{{SPARKLE}}}{name}"


def configuration():
    config = json.loads((ROOT / "src-tauri/tauri.conf.json").read_text())
    match = re.fullmatch(r"(\d{4})\.([1-9]|1[0-2])\.(0|[1-9]\d*)", config["version"])
    if not match:
        raise ValueError("Use a calendar SemVer without leading zeroes, e.g. 2026.6.2")
    year, month, patch = map(int, match.groups())
    build = config["bundle"]["macOS"]["bundleVersion"]
    if not re.fullmatch(r"[1-9]\d*", build):
        raise ValueError("bundleVersion must be a positive integer")
    return config, f"{year}.{month:02}.{patch}", int(build)


def read_feed(path=ROOT / "appcast.xml"):
    tree = ET.parse(path)
    if tree.find("channel") is None:
        raise ValueError("Missing appcast channel")
    return tree


def latest_build(tree):
    return max((int(item.findtext(sparkle("version"))) for item in tree.findall("channel/item")), default=0)


def prepare():
    _, version, build = configuration()
    tree = read_feed()
    latest = latest_build(tree)
    if build < latest:
        raise ValueError(f"Build {build} is older than published build {latest}")
    if build == latest:
        versions = [item.findtext(sparkle("shortVersionString")) for item in tree.findall("channel/item")
                    if item.findtext(sparkle("version")) == str(build)]
        if version not in versions:
            raise ValueError("A different version already uses this build number")
    output = f"version={version}\nbuild={build}\nneeded={str(build > latest).lower()}\n"
    print(output, end="")
    if os.environ.get("GITHUB_OUTPUT"):
        with open(os.environ["GITHUB_OUTPUT"], "a") as file:
            file.write(output)


def sign():
    config, version, build = configuration()
    bundle = ROOT / "src-tauri/target/universal-apple-darwin/release/bundle"
    app = bundle / "macos/Android Tools.app"
    with (app / "Contents/Info.plist").open("rb") as file:
        info = plistlib.load(file)
    expected = {
        "CFBundleIdentifier": "com.example.androidTools",
        "CFBundleVersion": str(build),
        "CFBundleShortVersionString": config["version"],
        "SUPublicEDKey": PUBLIC_KEY,
        "SUFeedURL": FEED_URL,
        "LSMinimumSystemVersion": config["bundle"]["macOS"]["minimumSystemVersion"],
    }
    for key, value in expected.items():
        if info.get(key) != value:
            raise ValueError(f"Unexpected bundle {key}: {info.get(key)!r}, expected {value!r}")
    framework = app / "Contents/Frameworks/Sparkle.framework"
    if not framework.is_dir():
        raise ValueError("Sparkle.framework is missing from the bundle")
    executable = app / "Contents/MacOS" / info["CFBundleExecutable"]
    subprocess.run(["lipo", str(executable),
                    "-verify_arch", "arm64", "x86_64"], check=True)
    for architecture in ("arm64", "x86_64"):
        result = subprocess.run(["otool", "-arch", architecture, "-l", str(executable)],
                                check=True, capture_output=True, text=True)
        if not re.search(r"cmd LC_RPATH\s+cmdsize \d+\s+path @executable_path/\.\./Frameworks \(offset \d+\)",
                         result.stdout):
            raise ValueError(f"Missing bundled framework runtime path for {architecture}")
        result = subprocess.run(["codesign", "--display", "--verbose=4", "--arch", architecture,
                                 str(executable)], check=True, capture_output=True, text=True)
        flags = re.search(r"\bflags=0x([0-9a-fA-F]+)", result.stderr)
        if not flags:
            raise ValueError(f"Missing code signing flags for {architecture}")
        # Match the legacy ad-hoc release: no Hardened Runtime or required library validation.
        if int(flags[1], 16) & (0x10000 | 0x2000):
            raise ValueError(f"Ad-hoc release must not enforce library Team IDs for {architecture}")
    subprocess.run(["codesign", "--verify", "--deep", "--strict", str(app)], check=True)
    images = list((bundle / "dmg").glob("*.dmg"))
    if len(images) != 1:
        raise ValueError("Expected exactly one universal DMG")
    dmg = ROOT / f"AndroidTools-{version}-macos.dmg"
    shutil.copyfile(images[0], dmg)
    key = os.environ.get("SPARKLE_PRIVATE_KEY", "").strip()
    if not key:
        raise ValueError("The existing SPARKLE_PRIVATE_KEY secret is required")
    # The key is never printed or stored in the workspace.
    with tempfile.TemporaryDirectory() as directory:
        key_file = Path(directory) / "sparkle.key"
        key_file.write_text(key)
        key_file.chmod(0o600)
        tool = str(ROOT / "src-tauri/sparkle-tools/sign_update")
        result = subprocess.run([tool, "--ed-key-file", str(key_file), str(dmg)],
                                check=True, capture_output=True, text=True)
        match = re.search(r'sparkle:edSignature="([^"]+)"', result.stdout)
        if not match or len(base64.b64decode(match[1], validate=True)) != 64:
            raise ValueError("Invalid Sparkle signature output")
    metadata = {
        "version": version, "build": build, "signature": match[1],
        "length": dmg.stat().st_size, "filename": dmg.name,
        "minimumSystemVersion": info["LSMinimumSystemVersion"],
        "pubDate": format_datetime(datetime.now(timezone.utc)),
    }
    (ROOT / "release-metadata.json").write_text(json.dumps(metadata, indent=2) + "\n")


def feed():
    metadata = json.loads((ROOT / "release-metadata.json").read_text())
    tree = read_feed()
    build = metadata["build"]
    version = metadata["version"]
    if build <= latest_build(tree):
        raise ValueError("The appcast already contains this build or a newer release")
    item = ET.Element("item")
    values = {
        "title": f"Version {version}",
        sparkle("version"): str(build),
        sparkle("shortVersionString"): version,
        sparkle("minimumSystemVersion"): metadata["minimumSystemVersion"],
        sparkle("releaseNotesLink"): f"https://github.com/{REPOSITORY}/releases/tag/{version}",
        "pubDate": metadata["pubDate"],
    }
    for key, value in values.items():
        ET.SubElement(item, key).text = value
    ET.SubElement(item, "enclosure", {
        "url": f"https://github.com/{REPOSITORY}/releases/download/{version}/{metadata['filename']}",
        sparkle("edSignature"): metadata["signature"],
        sparkle("os"): "macos",
        "length": str(metadata["length"]),
        "type": "application/octet-stream",
    })
    channel = tree.find("channel")
    items = channel.findall("item")
    channel.insert(list(channel).index(items[0]) if items else len(channel), item)
    ET.indent(tree, space="  ")
    tree.write(ROOT / "appcast.xml", encoding="utf-8", xml_declaration=True)


if __name__ == "__main__":
    {"prepare": prepare, "sign": sign, "feed": feed}[sys.argv[1]]()
