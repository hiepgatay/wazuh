# Hướng dẫn chạy & demo kịch bản Wazuh

> Chỉ thực hiện trên **lab do nhóm tự quản lý**. Không nhắm máy/host bên ngoài Internet.

| Kịch bản | Nền tảng | Mục tiêu | Rule / module | Script |
|----------|----------|----------|---------------|--------|
| **KB1** SSH Brute Force | Linux | Fail SSH nhiều lần → alert tương quan | `5710`, `5716`, `5763`… | `scripts/kb1-ssh-bruteforce.sh` |
| **KB2** FIM | Linux / **Windows** | Tạo / sửa / xóa `test.txt` | `550`, `553`, `554` + custom **100120** (Win) | `kb2-fim.sh` hoặc `run-scenarios.ps1 -Scenario fim` |
| **KB3** File hệ thống | Linux | Đổi file trong `/etc` | `550` + custom **100110** | `scripts/kb3-system-file.sh` |
| **KB4** Custom Rule | Linux / Windows | Chuỗi `WAZUH_LAB_ALERT` | **100100** | `kb4-custom-rule.sh` hoặc `-Scenario custom-log` |
| **KB5** Win Failed Logon | **Windows** | Đăng nhập sai → Event **4625** | `60104`… / `authentication_failed` | `kb5-win-failed-logon.ps1` |
| **KB6** Win Create User | **Windows** | Tạo user local → Event **4720** | mặc định + custom **100130** | `kb6-win-create-user.ps1` |

Dashboard: https://localhost — `admin` / `123456`

---

## Điều kiện trước khi demo

```powershell
cd "c:\Users\Dell P7730\Downloads\HĐH mạng"

# 1) Stack đang chạy
.\lab\scripts\run-scenarios.ps1 -Scenario status

# 2) Agent Active trên Dashboard → Agents

# 3) Nạp luật tùy chỉnh (KB3, KB4, KB2 Win, KB6)
.\lab\scripts\run-scenarios.ps1 -Scenario load-rules
```

**Cấu hình FIM / localfile (KB2, KB4 Windows):** trên máy có Agent — xem [Phụ lục A](#phụ-lục-a--cấu-hình-fim-lab).

### Demo nhanh theo nền tảng

```powershell
# --- Windows (máy có Agent) ---
.\lab\scripts\run-scenarios.ps1 -Scenario load-rules
.\lab\scripts\run-scenarios.ps1 -Scenario fim
.\lab\scripts\run-scenarios.ps1 -Scenario win-auth-fail
# KB6 cần PowerShell Admin:
.\lab\scripts\run-scenarios.ps1 -Scenario win-create-user
.\lab\scripts\run-scenarios.ps1 -Scenario custom-log

# --- Linux (SSH victim + agent) ---
.\lab\scripts\run-scenarios.ps1 -Scenario ssh -Target <IP_VICTIM>
# trên victim: sudo bash lab/scripts/kb3-system-file.sh
# trên victim: bash lab/scripts/kb4-custom-rule.sh
```

---

## Kịch bản 1 — SSH Brute Force (demo chính Linux)

### Ý tưởng
Máy attacker thử SSH nhiều lần với mật khẩu sai → agent victim ghi `Failed password` → Manager tạo alert; sau nhiều lần trong khung thời gian sẽ có alert mức cao hơn (brute-force).

```
[Attacker] --ssh fail x N--> [Victim + Agent] --> [Manager] --> Alert --> Dashboard
```

### Chuẩn bị
- **Victim:** Linux có `sshd` + Wazuh Agent Active (Ubuntu/VM/container lab).
- **Attacker:** máy khác trong lab (hoặc cùng host) có lệnh `ssh`.

### Cách A — Thủ công (dễ thuyết trình)

```bash
ssh nosuchuser@IP_VICTIM
# Nhập bất kỳ mật khẩu, lặp 8–12 lần, Ctrl+C thoát
```

### Cách B — Script

```bash
chmod +x lab/scripts/kb1-ssh-bruteforce.sh
./lab/scripts/kb1-ssh-bruteforce.sh IP_VICTIM
# Tuỳ chọn: ./lab/scripts/kb1-ssh-bruteforce.sh IP_VICTIM nosuchuser 12
```

PowerShell (WSL):

```powershell
.\lab\scripts\run-scenarios.ps1 -Scenario ssh -Target IP_VICTIM
```

Script chỉ gửi nhiều lần SSH với mật khẩu sai tới IP bạn chỉ định — **không** dùng Hydra/scan Internet.

### Xem kết quả trên Dashboard

```
rule.id:(5710 OR 5712 OR 5716 OR 5763 OR 5551)
```

| Giai đoạn | Rule thường gặp | Ý nghĩa |
|-----------|-----------------|----------|
| Fail đơn lẻ | 5716 / 5551 | Failed password |
| User không tồn tại | 5710 | Invalid user |
| Nhiều fail liên tiếp | **5763** | SSH brute force (tương quan) |

### Lời thuyết trình ngắn
> “Agent thu log `sshd`. Decoder SSH tách user/IP. Rule fail kích hoạt từng lần; rule frequency tương quan nhiều fail → alert brute-force mức cao hơn.”

### Screenshot
`lab/screenshots/05-ssh-or-auth-fail.png`

---

## Kịch bản 2 — File Integrity Monitoring (FIM)

### Ý tưởng
Tạo → sửa → xóa file trong thư mục FIM đang giám sát → Dashboard hiện alert syscheck. Trên Windows còn có custom rule **100120**.

### Chuẩn bị
Đã thêm thư mục lab vào FIM (Phụ lục A) và restart agent.

| Nền tảng | Thư mục lab |
|----------|-------------|
| Linux | `/tmp/wazuh-lab` |
| Windows | `C:\wazuh-lab` |

### Linux

```bash
chmod +x lab/scripts/kb2-fim.sh
./lab/scripts/kb2-fim.sh
```

### Windows

```powershell
.\lab\scripts\run-scenarios.ps1 -Scenario fim
```

### Xem kết quả

- Module **FIM**, hoặc Threat Hunting: `rule.groups:syscheck`
- Windows custom: `rule.id:100120`
- Lọc path: `syscheck.path:*wazuh-lab*`

| Hành động | Rule mặc định | Custom (Win) |
|-----------|---------------|--------------|
| Tạo file | 554 | **100120** |
| Sửa nội dung | 550 | **100120** |
| Xóa file | 553 | **100120** |

### Lời thuyết trình ngắn
> “FIM so hash/metadata với baseline. Mọi tạo/sửa/xóa trong thư mục giám sát đều thành alert — phát hiện backdoor hoặc đổi cấu hình trái phép.”

### Screenshot
`lab/screenshots/03-fim-alert.png`

---

## Kịch bản 3 — Phát hiện thay đổi file hệ thống (Linux)

### Ý tưởng
Luật custom **100110** nâng level khi FIM báo đổi `/etc/passwd` hoặc `/etc/shadow`.

### Cách chạy

```bash
chmod +x lab/scripts/kb3-system-file.sh
sudo ./lab/scripts/kb3-system-file.sh
```

Script: tạo marker trong `/etc`, thêm rồi xóa comment `# wazuh-lab-demo` ở `/etc/passwd` (không tạo user thật).

### Xem kết quả

```
rule.id:(550 OR 100110) AND syscheck.path:(/etc/passwd OR /etc/wazuh-lab-marker.conf)
```

| Alert | Rule | Level |
|-------|------|-------|
| FIM đổi file | 550 | mặc định |
| Đổi passwd/shadow (custom) | **100110** | **12** |

> Trên Windows dùng **KB6** (tạo user) thay cho chỉnh `/etc/passwd`.

### Screenshot
`lab/screenshots/06-system-file-alert.png`

---

## Kịch bản 4 — Custom Rule

### Ý tưởng
Chứng minh nhóm **tự tạo luật**:

```
Sinh sự kiện → Agent thu log → Manager
    → Decoder → Custom Rule 100100 → Alert → Dashboard
```

### Nạp luật + logtest

```powershell
.\lab\scripts\run-scenarios.ps1 -Scenario load-rules
$mgr = (docker ps --format "{{.Names}}" | Select-String "wazuh.manager").ToString()
docker exec -it $mgr /var/ossec/bin/wazuh-logtest
# Dán: Jan 1 12:00:00 testhost app: WAZUH_LAB_ALERT test message
```

**Kỳ vọng:** rule `100100`, level `10`.

### Sinh sự kiện

**Linux:**

```bash
./lab/scripts/kb4-custom-rule.sh
```

**Windows:**

```powershell
.\lab\scripts\run-scenarios.ps1 -Scenario custom-log
```

(Ghi `C:\wazuh-lab\lab-alerts.log` + Application Event Log — cần localfile Phụ lục A.)

### Dashboard

```
rule.id:100100
```

### Screenshot
`lab/screenshots/04-custom-rule-alert.png`

---

## Kịch bản 5 — Windows Failed Logon (Event 4625)

### Ý tưởng
Mô phỏng đăng nhập thất bại trên **chính máy Windows lab** (user giả + mật khẩu sai) → Security Event **4625** → Wazuh Agent → Dashboard. Tương đương “brute-force nhẹ” phía Windows so với KB1 SSH.

```
[LogonUser sai x N] → Event 4625 → Agent → Manager → Alert
```

### Cách chạy (máy có Agent Windows)

```powershell
.\lab\scripts\run-scenarios.ps1 -Scenario win-auth-fail
# hoặc:
.\lab\scripts\kb5-win-failed-logon.ps1 -Attempts 8
```

Không cần RDP; script gọi API `LogonUser` với user không tồn tại.

### Xem kết quả

**Event Viewer (máy Agent):** Windows Logs → Security → Event ID **4625**

**Dashboard:**

```
data.win.system.eventID:4625
```

hoặc:

```
rule.groups:authentication_failed
```

Rule Windows mặc định thường gặp: khoảng `60104`–`60107` (tùy phiên bản ruleset).

### Nếu không thấy 4625

Chạy **PowerShell Admin**:

```powershell
auditpol /set /subcategory:"Logon" /failure:enable
```

Rồi chạy lại KB5. Đợi 30–60s, chọn *Last 15 minutes* trên Dashboard.

### Lời thuyết trình ngắn
> “Trên Windows, đăng nhập sai sinh Event 4625. Agent đọc Security log; Manager áp rule authentication_failed — cùng ý tưởng với SSH fail trên Linux.”

### Screenshot
`lab/screenshots/07-win-auth-fail.png`

---

## Kịch bản 6 — Windows Create Local User (Event 4720)

### Ý tưởng
Tạo user local tạm `wazuh_lab_demo` rồi xóa → Event **4720** / **4726**. Custom rule **100130** đánh dấu lab (MITRE T1136 Create Account).

### Cách chạy (**PowerShell Run as Administrator**)

```powershell
.\lab\scripts\run-scenarios.ps1 -Scenario win-create-user
# hoặc:
.\lab\scripts\kb6-win-create-user.ps1
```

Script tự bật audit *User Account Management*, tạo user → chờ → xóa user.

### Xem kết quả

**Event Viewer:** Security → **4720** (created), **4726** (deleted)

**Dashboard:**

```
data.win.system.eventID:(4720 OR 4726)
```

```
rule.id:100130
```

```
data.win.eventdata.targetUserName:wazuh_lab_demo
```

### Lời thuyết trình ngắn
> “Tạo tài khoản mới là dấu hiệu persistence. Agent bắt Event 4720; nhóm thêm rule 100130 gắn MITRE T1136 để dễ lọc trên Dashboard.”

### Screenshot
`lab/screenshots/08-win-create-user.png`

---

## Thứ tự demo trước giảng viên (gợi ý)

### Phương án A — Có Linux victim (~15 phút)

| Phút | Việc |
|------|------|
| 0–2 | Dashboard + Agents Active |
| 2–6 | **KB1 SSH** |
| 6–9 | **KB2 FIM** (Win hoặc Linux) |
| 9–12 | **KB3** hoặc **KB6** |
| 12–15 | **KB4 Custom** |

### Phương án B — Chủ yếu Windows (~12 phút)

| Phút | Việc |
|------|------|
| 0–2 | Dashboard + Agent Windows Active |
| 2–5 | **KB2 FIM** (`C:\wazuh-lab`) |
| 5–8 | **KB5** Failed logon 4625 |
| 8–11 | **KB6** Create user 4720 / rule 100130 |
| 11–12 | **KB4** custom-log / logtest 100100 |

---

## Checklist kết quả

| # | Kịch bản | Thành công? | Rule / Event | Ảnh |
|---|----------|-------------|--------------|-----|
| 1 | SSH Brute Force | ☐ | 5716 / 5763… | `05-ssh-or-auth-fail.png` |
| 2 | FIM | ☐ | 550 / 553 / 554 / **100120** | `03-fim-alert.png` |
| 3 | File hệ thống (Linux) | ☐ | 550 / **100110** | `06-system-file-alert.png` |
| 4 | Custom Rule | ☐ | **100100** | `04-custom-rule-alert.png` |
| 5 | Win Failed Logon | ☐ | Event **4625** | `07-win-auth-fail.png` |
| 6 | Win Create User | ☐ | Event **4720** / **100130** | `08-win-create-user.png` |

---

## Phụ lục A — Cấu hình FIM lab

### Linux agent

Trong `/var/ossec/etc/ossec.conf`, khối `<syscheck>`:

```xml
<directories realtime="yes">/tmp/wazuh-lab</directories>
```

```bash
mkdir -p /tmp/wazuh-lab
sudo systemctl restart wazuh-agent
```

### Windows agent

File: `C:\Program Files (x86)\ossec-agent\ossec.conf`

Trong `<syscheck>`:

```xml
<directories realtime="yes">C:\wazuh-lab</directories>
```

Trong `<ossec_config>` (cho KB4 ghi file log):

```xml
<localfile>
  <location>C:\wazuh-lab\lab-alerts.log</location>
  <log_format>syslog</log_format>
</localfile>
```

```powershell
New-Item -ItemType Directory -Force -Path C:\wazuh-lab
Restart-Service Wazuh
```

Mẫu: `lab/config/agent-fim-lab-snippet.xml`.

> `realtime="yes"` giúp alert gần như tức thì — phù hợp demo.

---

## Phụ lục B — Xử lý lỗi nhanh

| Triệu chứng | Cách xử lý |
|-------------|------------|
| Không có alert SSH | Agent victim Active? `sshd` ghi auth.log? Đợi 30–60s |
| Không có alert FIM | Chưa thêm thư mục syscheck / chưa restart / chưa `realtime` |
| Rule 100100 không khớp | Chưa `load-rules`; thử `wazuh-logtest` |
| Rule 100110 không lên | Path đúng `/etc/passwd`; rule cha 550 phải kích hoạt |
| Không thấy Event 4625 | `auditpol /set /subcategory:"Logon" /failure:enable` (Admin) |
| Không thấy Event 4720 | Chạy KB6 bằng **Admin**; kiểm tra audit Account Management |
| Rule 100130 không lên | Vẫn thấy 4720 mặc định cũng đủ demo; nạp lại `local_rules.xml` |
| Dashboard chậm | Refresh, *Last 15 minutes* |
