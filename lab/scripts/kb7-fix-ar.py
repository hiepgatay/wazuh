"""Dam bao command + active-response win_kill_malware nam trong ossec.conf."""
from pathlib import Path

conf = Path("/var/ossec/etc/ossec.conf")
text = conf.read_text(encoding="utf-8")

block = """
<ossec_config>
  <localfile>
    <log_format>syslog</log_format>
    <location>/var/ossec/logs/active-responses.log</location>
  </localfile>

  <command>
    <name>win_kill_malware</name>
    <executable>kill_malware.cmd</executable>
    <timeout_allowed>yes</timeout_allowed>
  </command>

  <active-response>
    <disabled>no</disabled>
    <command>win_kill_malware</command>
    <location>local</location>
    <rules_id>100010,100011</rules_id>
    <timeout>60</timeout>
  </active-response>
</ossec_config>
"""

# Xoa block AR cu neu co
import re

text2 = re.sub(
    r"<ossec_config>\s*<localfile>\s*<log_format>syslog</log_format>\s*"
    r"<location>/var/ossec/logs/active-responses\.log</location>\s*</localfile>[\s\S]*?</ossec_config>\s*\Z",
    "",
    text,
    count=1,
)
if text2 == text:
    # fallback: strip trailing win_kill block
    text2 = re.sub(
        r"<command>\s*<name>win_kill_malware</name>[\s\S]*?</active-response>\s*</ossec_config>\s*\Z",
        "",
        text,
    )
    # keep last ossec_config localfile if broken
    if "<location>/var/ossec/logs/active-responses.log</location>" not in text2.split("<command>")[0][-500:]:
        pass

text2 = text2.rstrip() + "\n" + block.strip() + "\n"
conf.write_text(text2, encoding="utf-8")
print("ar-fixed")
