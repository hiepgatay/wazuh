# Hệ thống phát hiện tấn công, xâm nhập — Wazuh

Lab thực hành triển khai **Wazuh 4.14.8** (Docker single-node) để giám sát endpoint, phát hiện xâm nhập và cảnh báo tập trung.

## Wazuh giải quyết gì?

Firewall và antivirus thường chỉ chặn ở biên hoặc theo chữ ký mã độc. Nhiều tấn công vẫn xảy ra **bên trong** hệ thống: dò mật khẩu SSH/RDP, sửa file cấu hình, tạo tài khoản lạ, cài persistence, khai thác lỗ hổng phần mềm…

**Wazuh** là nền tảng mã nguồn mở kiểu **XDR + SIEM**: thu thập sự kiện từ máy chủ/máy trạm, phân tích bằng decoder + ruleset, lưu trữ và hiển thị cảnh báo. Có thể kết hợp **Active Response** để phản ứng tự động (ví dụ chặn IP).

So với các lớp bảo mật khác:

| Lớp | Vai trò | Ví dụ |
|-----|---------|--------|
| NIDS | Giám sát lưu lượng mạng | Suricata, Snort |
| Antivirus | Chữ ký / heuristic file | Defender, ClamAV |
| **Wazuh (HIDS/XDR)** | Log, FIM, SCA, lỗ hổng, tương quan trên host | Lab này |

Wazuh **không thay** NIDS; thực tế thường dùng kèm nhau.

## Kiến trúc hệ thống

```
[Endpoint + Agent]  --TCP 1514 (AES)-->  [Wazuh Manager]
        |                                      |
   log / FIM / SCA                      decode → rule match → alert
                                               |
                                        [Wazuh Indexer]
                                               |
                                        [Dashboard :443]
```

| Thành phần | Nhiệm vụ |
|------------|----------|
| **Agent** | Chạy trên Linux / Windows / macOS: đọc log, FIM, SCA, rootcheck, nhận lệnh Active Response |
| **Manager** | Nhận sự kiện, decode, so khớp luật, tương quan, tạo alert; đăng ký agent (cổng 1515) |
| **Indexer** | Lưu trữ và tìm kiếm alert / sự kiện (OpenSearch) |
| **Dashboard** | Giao diện Threat Hunting, Agents, FIM, Vulnerability, Compliance |

Cổng quan trọng trong lab:

| Cổng | Mục đích |
|------|----------|
| **443** | Dashboard (HTTPS) |
| **1514** | Agent gửi sự kiện |
| **1515** | Đăng ký / enrollment agent |
| **55000** | Wazuh API |
| **9200** | Indexer |

Không cùng mạng LAN: xem Dashboard qua tunnel HTTP (ví dụ ngrok); cài agent từ xa nên dùng VPN (Tailscale/ZeroTier) tới IP máy host — **không** dùng `127.0.0.1` và **không** dùng URL dashboard làm Server address.

## Cơ chế phát hiện

Luồng xử lý mỗi sự kiện:

1. **Thu thập** — Agent đọc log hệ thống/ứng dụng, quét FIM, chạy SCA…
2. **Gửi về Manager** — Mã hóa AES, cổng 1514 (hoặc Syslog agentless)
3. **Decode** — Tách trường (user, srcip, path, program…)
4. **Rule matching** — So khớp hàng nghìn luật có sẵn + luật tùy chỉnh
5. **Tương quan** — Frequency / timeframe (ví dụ nhiều lần login fail liên tiếp)
6. **Alert** — Gán `level` (0–15), nhóm, MITRE ATT&CK nếu có
7. **Index + hiển thị** — Lưu Indexer, xem trên Dashboard
8. **(Tuỳ chọn) Active Response** — Chạy script / chặn IP theo rule

### Các khả năng phát hiện chính

| Khả năng | Phát hiện gì | Trong lab |
|----------|--------------|-----------|
| **Log analysis** | SSH invalid user, brute-force, lỗi auth Windows, web/app log | Agent + ruleset mặc định |
| **FIM (File Integrity Monitoring)** | Tạo / sửa / xóa file quan trọng | Script `fim`, thư mục giám sát |
| **Custom rules** | Chuỗi / hành vi riêng của nhóm | `lab/rules/local_rules.xml` |
| **SCA** | Cấu hình máy lệch CIS / baseline | Module SCA trên agent |
| **Vulnerability** | Phần mềm có CVE đã biết | Inventory + feed lỗ hổng |
| **Rootcheck / malware signals** | Dấu hiệu rootkit, tiến trình lạ | Module agent |
| **Active Response** | Phản ứng sau khi có alert | Bật khi cần demo ngăn chặn |

### Luật tùy chỉnh trong repo

File `lab/rules/local_rules.xml` (ID lab `100000–120000`):

- **100100** (`level 10`) — Chuỗi `WAZUH_LAB_ALERT` (MITRE T1070)
- **100110** (`level 12`) — FIM đổi `/etc/passwd` hoặc `/etc/shadow` (MITRE T1098)
- **100120** (`level 10`) — FIM thư mục Windows `C:\wazuh-lab` (MITRE T1565)
- **100130** (`level 10`) — Tạo tài khoản Windows lab (MITRE T1136)

Nạp lên manager rồi restart; kiểm thử bằng `wazuh-logtest` (xem `lab/HUONG-DAN-CAI-DAT.md`).

## Cấu trúc thư mục

| Đường dẫn | Nội dung |
|-----------|----------|
| `lab/HUONG-DAN-CAI-DAT.md` | Cài Docker stack, agent, nạp luật, xử lý lỗi |
| `lab/HUONG-DAN-DEMO-KICH-BAN.md` | **Demo 6 kịch bản**: SSH, FIM, `/etc`, Custom, Win 4625, Win tạo user |
| `lab/rules/local_rules.xml` | Luật phát hiện tùy chỉnh |
| `lab/scripts/run-scenarios.ps1` | `status`, `load-rules`, `ssh`, `fim`, `system-file`, `custom-log`, `win-auth-fail`, `win-create-user` |
| `lab/scripts/kb1-*.sh` … `kb4-*.sh` | Script bash (Linux / WSL) |
| `lab/scripts/kb5-win-*.ps1`, `kb6-win-*.ps1` | Script PowerShell demo Windows |
| `lab/wazuh-docker/` | Wazuh Docker official (v4.14.8), dùng `single-node` |
| `lab/screenshots/` | Ảnh Dashboard (agent active, FIM, custom alert…) |

## Chạy nhanh lab

Yêu cầu: Windows + Docker Desktop (WSL2), RAM khuyến nghị ≥ 8–16 GB trống, cổng 443/1514/1515/55000/9200 trống.

```powershell
# 1) Indexer cần max_map_count
wsl -d docker-desktop -u root sysctl -w vm.max_map_count=262144

# 2) Chứng chỉ (lần đầu) + khởi động
cd "lab\wazuh-docker\single-node"
docker compose -f generate-indexer-certs.yml run --rm generator
docker compose up -d
docker compose ps
```

- Dashboard: https://localhost — `admin` / `123456` (chấp nhận chứng chỉ tự ký)
- Chi tiết agent, FIM, nạp luật: `lab/HUONG-DAN-CAI-DAT.md`

```powershell
# Trạng thái / nạp luật / kịch bản thử nghiệm
.\lab\scripts\run-scenarios.ps1 -Scenario status
.\lab\scripts\run-scenarios.ps1 -Scenario load-rules
.\lab\scripts\run-scenarios.ps1 -Scenario ssh -Target <IP_VICTIM>
.\lab\scripts\run-scenarios.ps1 -Scenario fim
.\lab\scripts\run-scenarios.ps1 -Scenario system-file
.\lab\scripts\run-scenarios.ps1 -Scenario custom-log
# Windows (máy có Agent):
.\lab\scripts\run-scenarios.ps1 -Scenario win-auth-fail
.\lab\scripts\run-scenarios.ps1 -Scenario win-create-user   # PowerShell Admin

# Chi tiết từng bước demo: lab\HUONG-DAN-DEMO-KICH-BAN.md

# Log manager
cd "lab\wazuh-docker\single-node"
docker compose logs --tail 50 wazuh.manager
```

Dừng stack: `docker compose down` (thêm `-v` nếu muốn xóa dữ liệu Indexer).

## Kiểm chứng phát hiện trên Dashboard

Sau khi agent **Active** và đã kích hoạt kịch bản:

1. **Agents** — Endpoint online
2. **Threat Hunting / Security events** — Lọc `syscheck`, `authentication_failed`, `nos_lab`…
3. **FIM** — Alert tạo/sửa/xóa trong thư mục giám sát (`rule.id:100120` trên Windows)
4. **Custom rule** — `100100` khi log chứa `WAZUH_LAB_ALERT`
5. **Windows** — Event `4625` (KB5), `4720` / rule `100130` (KB6)

Mỗi alert thường gồm: thời gian, agent, rule id/level, mô tả, (nếu có) MITRE technique — đó là đầu ra của hệ thống phát hiện tấn công / xâm nhập trong lab này.
