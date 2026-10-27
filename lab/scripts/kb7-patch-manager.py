"""Chen Active Response KB7 vao ossec.conf neu chua co."""
from pathlib import Path

conf = Path("/var/ossec/etc/ossec.conf")
extra = Path("/tmp/kb7-ar.xml").read_text(encoding="utf-8").strip()
text = conf.read_text(encoding="utf-8")
if "win_kill_malware" in text:
    print("already")
    raise SystemExit(0)
idx = text.rfind("</ossec_config>")
if idx < 0:
    raise SystemExit("no ossec_config close tag")
conf.write_text(text[:idx] + "\n" + extra + "\n" + text[idx:], encoding="utf-8")
print("patched")
