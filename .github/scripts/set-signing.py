#!/usr/bin/env python3
"""Switches the SayMathJr app target (only) to manual App Store signing for a CI build.

Signing settings are written into the app target's build configurations instead of being
passed on the xcodebuild command line, because command-line settings also hit the
test target, which must not take the app profile.

Usage: set-signing.py PROJECT.pbxproj  (reads TEAM, BUNDLE_ID, PROFILE_NAME, VER, BUILD from the environment)
"""
import os
import re
import sys

path = sys.argv[1]
text = open(path).read()
env = os.environ
cloud = env.get("SIGN_MODE") == "cloud"
wanted = {
    "DEVELOPMENT_TEAM": env["TEAM"],
    "CODE_SIGN_STYLE": "Manual",
    '"CODE_SIGN_IDENTITY[sdk=iphoneos*]"': '"Apple Distribution"',
    "CODE_SIGN_IDENTITY": '"Apple Distribution"',
    "PROVISIONING_PROFILE_SPECIFIER": '"%s"' % env["PROFILE_NAME"],
    "PRODUCT_BUNDLE_IDENTIFIER": env["BUNDLE_ID"],
    "MARKETING_VERSION": env["VER"],
    "CURRENT_PROJECT_VERSION": env["BUILD"],
}
if cloud:
    # Apple cloud signing: Xcode picks the certificate and makes the profile with the API key.
    wanted["CODE_SIGN_STYLE"] = "Automatic"
    for k in ('"CODE_SIGN_IDENTITY[sdk=iphoneos*]"', "CODE_SIGN_IDENTITY", "PROVISIONING_PROFILE_SPECIFIER"):
        del wanted[k]
    drop = ('"CODE_SIGN_IDENTITY[sdk=iphoneos*]"', "CODE_SIGN_IDENTITY", "PROVISIONING_PROFILE_SPECIFIER")
else:
    drop = ()

# The app target's configurations are the ones with the app's base bundle ID.
block_re = re.compile(r"(buildSettings = \{\n)(.*?)(\n\t\t\t\};)", re.S)
changed = 0


def fix(m):
    global changed
    body = m.group(2)
    if "PRODUCT_BUNDLE_IDENTIFIER = com.saystudios.saymathjr;" not in body:
        return m.group(0)
    lines = [l for l in body.split("\n")
             if not any(re.match(r"\s*%s = " % re.escape(k), l) for k in list(wanted) + list(drop))]
    lines += ["\t\t\t\t%s = %s;" % (k, v) for k, v in wanted.items()]
    changed += 1
    return m.group(1) + "\n".join(lines) + m.group(3)


text = block_re.sub(fix, text)
if changed != 2:
    sys.exit("Expected 2 app build configurations, changed %d" % changed)
open(path, "w").write(text)
print("App target set to %s signing, version %s (%s)" % ("Apple cloud" if cloud else "manual (profile %r)" % env["PROFILE_NAME"], env["VER"], env["BUILD"]))
