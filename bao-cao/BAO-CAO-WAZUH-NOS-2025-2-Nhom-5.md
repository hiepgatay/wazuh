# BÁO CÁO MÔN HỌC HỆ ĐIỀU HÀNH MẠNG

## Hệ thống phát hiện tấn công, xâm nhập Wazuh

**Mã học phần:** NOS  
**Học kỳ:** 2025-2  
**Nhóm:** 5  
**Tên file nộp:** NOS – 2025-2 - Nhóm 5.pdf

| STT | Họ và tên | MSSV | Vai trò |
|-----|-----------|------|---------|
| 1   | *(điền)*  |      | TV1 – Giới thiệu & kiến trúc |
| 2   | *(điền)*  |      | TV2 – Thành phần & cơ chế |
| 3   | *(điền)*  |      | TV3 – Tính năng & luật |
| 4   | *(điền)*  |      | TV4 – Cài đặt, thử nghiệm, kết luận |

**Giảng viên hướng dẫn:** *(điền)*  
**Ngày hoàn thành:** *(điền)*

---

> **Ghi chú biên tập:** File Markdown này là bản thảo nội dung đầy đủ để nhóm chuyển sang Word/PDF (~25–30 trang). Chèn ảnh lab từ thư mục `lab/screenshots/`, điền tên thành viên, và bổ sung số trang theo mẫu trường.

---

# MỤC LỤC

1. Giới thiệu  
2. Tổng quan về Wazuh  
3. Kiến trúc hệ thống  
4. Các thành phần và cơ chế hoạt động  
5. Tính năng chính  
6. Luật phát hiện và cách tạo luật  
7. Cài đặt và cấu hình  
8. Thử nghiệm các kịch bản phát hiện  
9. Ưu điểm và nhược điểm  
10. Kết luận  
11. Tài liệu tham khảo  
Phụ lục

---

# CHƯƠNG 1. GIỚI THIỆU

## 1.1. Bối cảnh

Trong môi trường doanh nghiệp và trung tâm dữ liệu hiện đại, số lượng thiết bị đầu cuối, máy chủ và dịch vụ mạng tăng nhanh. Đồng thời, các cuộc tấn công mạng ngày càng đa dạng: dò mật khẩu (brute-force), leo thang đặc quyền, cài mã độc, thay đổi tệp cấu hình nhạy cảm, khai thác lỗ hổng phần mềm, v.v. Việc chỉ dựa vào tường lửa (firewall) hoặc phần mềm diệt virus truyền thống thường **không đủ** để phát hiện sớm hành vi bất thường bên trong hệ thống.

Các lớp công nghệ liên quan gồm:

- **IDS (Intrusion Detection System):** phát hiện xâm nhập, cảnh báo.
- **IPS (Intrusion Prevention System):** phát hiện và ngăn chặn.
- **SIEM (Security Information and Event Management):** thu thập, tương quan và phân tích log tập trung.
- **XDR (Extended Detection and Response):** mở rộng phạm vi phát hiện/phản ứng trên endpoint, đám mây, mạng…

## 1.2. Lý do chọn Wazuh

**Wazuh** là nền tảng bảo mật mã nguồn mở (open source) cung cấp khả năng **XDR và SIEM**. Hệ thống kế thừa và phát triển từ dự án OSSEC, với cộng đồng lớn, tài liệu chính thức đầy đủ và khả năng triển khai linh hoạt (on-premise, máy ảo, Docker, đám mây).

Wazuh phù hợp làm đề tài môn học vì:

1. Có thể cài đặt lab với chi phí thấp (Docker trên máy cá nhân).
2. Có sẵn hàng nghìn luật phát hiện (ruleset).
3. Cho phép sinh viên **tự viết luật** và kiểm thử bằng công cụ `wazuh-logtest`.
4. Có giao diện Dashboard trực quan để minh họa kết quả thử nghiệm.

## 1.3. Mục tiêu báo cáo

- Trình bày khái niệm, kiến trúc, thành phần và cơ chế hoạt động của Wazuh.
- Phân tích các tính năng chính, hệ thống luật và quy trình tạo luật tùy chỉnh.
- Thực hiện cài đặt môi trường lab và thử nghiệm một số kịch bản phát hiện đơn giản.
- Đánh giá ưu/nhược điểm và rút ra kết luận phục vụ học tập, vận hành thực tế.

## 1.4. Phạm vi và phương pháp

- **Phạm vi:** tập trung Wazuh phiên bản ổn định gần đây (nhóm lab dùng nhánh Docker `v4.14.8`), triển khai **single-node** phục vụ thử nghiệm, không đi sâu cluster sản xuất quy mô lớn.
- **Phương pháp:** nghiên cứu tài liệu chính thức, tổng hợp lý thuyết, thực nghiệm cài đặt và mô phỏng tấn công an toàn trong môi trường lab có kiểm soát.

## 1.5. Cấu trúc báo cáo

Báo cáo gồm phần giới thiệu; phần nội dung (kiến trúc, thành phần, cơ chế, tính năng, luật, cài đặt, thử nghiệm, ưu/nhược điểm); kết luận và tài liệu tham khảo.

---

# CHƯƠNG 2. TỔNG QUAN VỀ WAZUH

## 2.1. Wazuh là gì?

Theo tài liệu chính thức, nền tảng Wazuh cung cấp các tính năng XDR/SIEM để bảo vệ khối lượng công việc trên máy chủ, container và đám mây, bao gồm: phân tích log, phát hiện xâm nhập và mã độc, giám sát toàn vẹn tệp (FIM), đánh giá cấu hình (SCA), phát hiện lỗ hổng, hỗ trợ tuân thủ quy định…

Giải pháp dựa trên:

- **Wazuh agent** cài trên các endpoint cần giám sát.
- Ba thành phần trung tâm: **Wazuh server**, **Wazuh indexer**, **Wazuh dashboard**.

Ngoài giám sát có agent, Wazuh còn hỗ trợ **agentless** (ví dụ nhận log qua Syslog từ firewall, switch, router).

## 2.2. Vai trò trong hệ thống bảo mật

Wazuh đóng vai trò lớp **phát hiện – phân tích – cảnh báo – (tùy chọn) phản ứng**:

| Lớp | Việc Wazuh thực hiện |
|-----|----------------------|
| Thu thập | Log hệ thống, sự kiện bảo mật, inventory, checksum tệp… |
| Phân tích | Decoder + ruleset + threat intelligence |
| Lưu trữ | Indexer lưu alert/event để truy vấn |
| Trực quan | Dashboard, báo cáo tuân thủ |
| Phản ứng | Active Response (chặn IP, chạy script…) |

## 2.3. So sánh nhanh với một số giải pháp liên quan

| Tiêu chí | Wazuh | Suricata (NIDS) | Elastic SIEM (thương mại/tự dựng) |
|----------|-------|-----------------|-----------------------------------|
| Trọng tâm | Endpoint + log + FIM/SCA/Vuln | Traffic mạng | Log tập trung rộng |
| Chi phí license | Mã nguồn mở | Mã nguồn mở | Tùy gói |
| Agent đa nền tảng | Có | Không (sensor mạng) | Có (Beats…) |
| Luật tùy chỉnh | XML ruleset mạnh | Suricata rules | Detection rules riêng |

Wazuh **không thay thế** hoàn toàn NIDS như Suricata; thực tế thường kết hợp: Suricata giám sát mạng, Wazuh giám sát host và tương quan sự kiện.

---

# CHƯƠNG 3. KIẾN TRÚC HỆ THỐNG

## 3.1. Mô hình kiến trúc tổng quát

Kiến trúc Wazuh gồm agent đa nền tảng và ba thành phần trung tâm. Luồng dữ liệu cơ bản:

```
[Endpoint + Agent] --(1514/TCP, AES)--> [Wazuh Server]
                                              |
                                         Filebeat/TLS
                                              v
                                        [Wazuh Indexer]
                                              ^
                                              | HTTPS query
                                        [Wazuh Dashboard]
                                              |
                                    API Server :55000 (cấu hình/trạng thái)
```

*(Nhóm chèn hình vẽ kiến trúc tại đây — Hình 3.1)*

## 3.2. Các mô hình triển khai

1. **All-in-one:** Server + Indexer + Dashboard trên một máy. Phù hợp lab, môi trường nhỏ.
2. **Single-node (tách máy/container):** mỗi thành phần một instance riêng. Phù hợp quy mô vừa.
3. **Multi-node:** cluster Server và/hoặc cluster Indexer, Dashboard, có thể có reverse proxy. Phù hợp môi trường lớn, cần HA.

Trong lab môn học, nhóm chọn **Docker single-node** vì dễ dựng lại, đủ minh họa đầy đủ thành phần.

## 3.3. Giao tiếp giữa các thành phần

### 3.3.1. Agent ↔ Server
Agent gửi sự kiện tới dịch vụ kết nối agent (mặc định TCP **1514**). Đăng ký agent dùng cổng **1515**. Giao thức mặc định mã hóa **AES** (128-bit block, khóa 256-bit); Blowfish là tùy chọn.

### 3.3.2. Server ↔ Indexer
Server dùng **Filebeat** đẩy alert/event sang Indexer (mặc định **9200/TCP**) qua TLS.

### 3.3.3. Dashboard ↔ Server / Indexer
- Dashboard gọi **Wazuh API** (mặc định **55000**) để xem cấu hình, trạng thái agent.
- Dashboard truy vấn Indexer để hiển thị alert, dashboard bảo mật, tuân thủ…

## 3.4. Cổng mạng mặc định

| Thành phần | Cổng | Giao thức | Mục đích |
|------------|------|-----------|----------|
| Server | 1514 | TCP | Kết nối agent |
| Server | 1515 | TCP | Enrollment agent |
| Server | 1516 | TCP | Cluster daemon |
| Server | 514 | UDP/TCP | Syslog (tùy chọn) |
| Server | 55000 | TCP | REST API |
| Indexer | 9200 | TCP | API indexer |
| Indexer | 9300–9400 | TCP | Cluster indexer |
| Dashboard | 443 | TCP | Giao diện web (map tới 5601 trong container) |

---

# CHƯƠNG 4. CÁC THÀNH PHẦN VÀ CƠ CHẾ HOẠT ĐỘNG

## 4.1. Wazuh Agent

Agent cài trên endpoint (Linux, Windows, macOS, một số Unix). Nhiệm vụ chính:

- Đọc log hệ thống / ứng dụng.
- Thu thập inventory phần mềm, cổng mở, tiến trình…
- Chạy module FIM, SCA, rootcheck, vulnerability detection (phối hợp server)…
- Thực thi Active Response khi được lệnh từ server.
- Duy trì kết nối an toàn với manager.

## 4.2. Wazuh Server (Manager)

Server là “bộ não” phân tích:

1. Nhận sự kiện từ agent / syslog.
2. **Pre-decoding** (timestamp, hostname, program…).
3. **Decoding** (trích field: user, srcip, path…).
4. **Rule matching** (so khớp ruleset, tương quan frequency/timeframe).
5. Sinh **alert** theo mức độ (level).
6. Ghi output và chuyển sang Indexer.
7. Quản lý agent (nhóm, cấu hình tập trung, nâng cấp từ xa khi cấu hình).

## 4.3. Wazuh Indexer

Indexer là engine tìm kiếm/phân tích toàn văn, lưu trữ alert và dữ liệu liên quan, hỗ trợ truy vấn nhanh cho Dashboard. Cần cấu hình kernel `vm.max_map_count` đủ lớn khi chạy trên Linux/WSL.

## 4.4. Wazuh Dashboard

Giao diện web tập trung: Threat Hunting, FIM, SCA, Vulnerability, Compliance (PCI DSS, GDPR, HIPAA, NIST…), quản lý agent, xem rule/alert.

Tài khoản mặc định lab Docker (cần đổi trên môi trường thật):

- Username: `admin`
- Password: `123456`

## 4.5. Cơ chế phát hiện end-to-end

Ví dụ đăng nhập SSH thất bại:

1. `sshd` ghi log `/var/log/auth.log` (Linux).
2. Agent đọc log, gửi về Server.
3. Decoder SSH nhận diện sự kiện.
4. Rule (ví dụ 5710 – invalid user, 5716 – authentication failed…) khớp → alert.
5. Nếu nhiều lần thất bại trong khoảng thời gian: rule tương quan (ví dụ brute-force **5763**) tăng mức độ.
6. Alert vào Indexer → hiện trên Dashboard.
7. (Tùy chọn) Active Response chạy `firewall-drop` chặn IP nguồn.

## 4.6. Giám sát không agent (Agentless)

Thiết bị mạng có thể gửi Syslog về Server (cổng 514) hoặc được kiểm tra cấu hình định kỳ qua SSH/API. Phù hợp firewall, switch không cài được agent.

---

# CHƯƠNG 5. TÍNH NĂNG CHÍNH

## 5.1. Phân tích log và phát hiện xâm nhập

Wazuh phân tích log từ hệ điều hành và ứng dụng (SSH, web server, malware logs…). Ruleset sẵn có bao phủ nhiều CVE/IOC phổ biến; có thể mở rộng bằng luật tùy chỉnh.

## 5.2. File Integrity Monitoring (FIM)

Theo dõi tạo/sửa/xóa tệp trong thư mục đăng ký (ví dụ `/etc`, thư mục web). Hữu ích phát hiện backdoor, thay đổi cấu hình trái phép. Có thể viết luật FIM tùy chỉnh theo tên tệp, quyền, nội dung.

## 5.3. Security Configuration Assessment (SCA)

Kiểm tra cấu hình theo policy (CIS…). Kết quả “pass/fail” giúp cứng hóa hệ thống.

## 5.4. Vulnerability Detection

Đối chiếu inventory phần mềm trên agent với cơ sở dữ liệu lỗ hổng (kết hợp nguồn CTI). Giúp ưu tiên vá lỗi.

## 5.5. Malware / Rootkit detection

Module rootcheck và tích hợp feed/IOC hỗ trợ phát hiện dấu hiệu rootkit, tệp đáng ngờ.

## 5.6. Active Response

Khi alert thỏa điều kiện, Server yêu cầu Agent chạy script (chặn IP iptables/Windows firewall, vô hiệu hóa tài khoản…). Cần thận trọng để tránh chặn nhầm (false positive).

## 5.7. Tuân thủ và báo cáo

Dashboard có sẵn khung nhìn PCI DSS, GDPR, HIPAA, NIST 800-53, CIS… hỗ trợ kiểm toán.

## 5.8. Giám sát đám mây và container

Wazuh hỗ trợ tích hợp AWS/Azure/GCP, giám sát Docker/Kubernetes (tùy module cấu hình). Trong phạm vi môn học, nhóm chỉ đề cập ở mức khái niệm.

---

# CHƯƠNG 6. LUẬT PHÁT HIỆN VÀ CÁCH TẠO LUẬT

## 6.1. Khái niệm ruleset

Luật Wazuh viết dạng XML, tổ chức theo nhóm (`<group>`). Mỗi luật có:

- `id`: mã luật
- `level`: 0–15 (0 thường là “ignore”; càng cao càng nghiêm trọng)
- Điều kiện: `match`, `regex`, `field`, `if_sid`, `if_group`, `frequency`, `timeframe`…
- `description`, ánh xạ MITRE ATT&CK, nhóm tuân thủ…

**Quy ước quan trọng:** luật tùy chỉnh dùng ID từ **100000 đến 120000** để tránh trùng ruleset mặc định.

## 6.2. Vị trí file luật

| Mục đích | Đường dẫn trên Server |
|----------|------------------------|
| Luật tùy chỉnh nhỏ | `/var/ossec/etc/rules/local_rules.xml` |
| Bộ luật lớn | `/var/ossec/etc/rules/*.xml` (file mới) |
| Ruleset mặc định | `/var/ossec/ruleset/rules/` (**không sửa trực tiếp** — sẽ mất khi nâng cấp) |

Muốn sửa luật mặc định: copy sang `etc/rules/`, chỉnh và thêm `overwrite="yes"`.

## 6.3. Ví dụ tạo luật mới

Giả sử log mẫu:

```text
Dec 25 20:45:02 MyHost example[12345]: User 'admin' logged from '192.168.1.100'
```

Thêm vào `local_rules.xml`:

```xml
<group name="custom_rules_example,">
  <rule id="100010" level="5">
    <program_name>example</program_name>
    <description>Phat hien dang nhap chuong trinh example</description>
  </rule>
</group>
```

## 6.4. Kiểm thử bằng wazuh-logtest

```bash
/var/ossec/bin/wazuh-logtest
```

Dán một dòng log → công cụ hiện 3 pha: pre-decoding, decoding, filtering (rules).  
**Lưu ý:** logtest nhận file đã lưu; muốn alert thật trên hệ thống thì **restart wazuh-manager**.

## 6.5. Ghi đè luật mặc định

Ví dụ nâng level rule SSH 5710 từ 5 lên 10:

```xml
<group name="syslog,sshd,">
  <rule id="5710" level="10" overwrite="yes">
    <if_sid>5700</if_sid>
    <match>illegal user|invalid user</match>
    <description>sshd: Attempt to login using a non-existent user</description>
  </rule>
</group>
```

Không thể ghi đè một số nhãn liên kết (`if_sid`, `if_matched_sid`…) theo hạn chế hiện tại của Wazuh — các nhãn này bị bỏ qua khi overwrite.

## 6.6. Luật tương quan (correlation)

Ví dụ ý tưởng brute-force: nếu cùng `srcip` khớp rule đăng nhập thất bại **N lần** trong **T giây** thì kích hoạt rule mức cao hơn. Ruleset SSH sẵn có các rule kiểu này (nhóm lab dùng sẵn để demo).

## 6.7. Luật FIM tùy chỉnh (ý tưởng)

- Tăng level khi sửa file cực kỳ quan trọng (`/etc/passwd`, web shell path…).
- Cảnh báo riêng khi xóa file trong thư mục giám sát.
- Gắn MITRE (ví dụ T1070 – Indicator Removal, T1222 – File Permissions Modification…).

## 6.8. Luật lab của nhóm (`lab/rules/local_rules.xml`)

| Rule ID | Level | Mục đích | Kịch bản |
|---------|-------|----------|----------|
| **100100** | 10 | Khớp chuỗi `WAZUH_LAB_ALERT` | KB4 |
| **100110** | 12 | FIM đổi `/etc/passwd` hoặc `/etc/shadow` | KB3 |
| **100120** | 10 | FIM thư mục Windows `C:\wazuh-lab` | KB2 (Win) |
| **100130** | 10 | Đánh dấu tạo tài khoản Windows (lab) | KB6 |

Chi tiết cấu hình lab nằm ở Chương 7–8 và thư mục `lab/`.

---

# CHƯƠNG 7. CÀI ĐẶT VÀ CẤU HÌNH

## 7.1. Yêu cầu lab (Docker single-node)

Theo tài liệu Wazuh Docker:

- CPU ≥ 4 lõi  
- RAM ≥ 8 GB (máy nhóm: ~31 GB)  
- Ổ đĩa ≥ 50 GB trống cho image/volume  
- Docker Engine/Desktop + Docker Compose + Git  
- Trên Linux/WSL: `vm.max_map_count=262144`

## 7.2. Kiến trúc lab nhóm

| Thành phần | Hình thức | Ghi chú |
|------------|-----------|---------|
| Manager + Indexer + Dashboard | Docker Compose single-node | Host Windows + Docker Desktop |
| Agent | Windows host và/hoặc container agent | Giám sát endpoint thật |
| Attacker giả lập | Cùng máy / WSL | Chỉ dùng lệnh an toàn, không tấn công hệ thống ngoài lab |

## 7.3. Các bước cài Manager stack

```powershell
# 1) Clone repo đúng tag
git clone https://github.com/wazuh/wazuh-docker.git -b v4.14.8
cd wazuh-docker/single-node

# 2) Sinh chứng chỉ
docker compose -f generate-indexer-certs.yml run --rm generator

# 3) (WSL/Docker Desktop) tăng vm.max_map_count
wsl -d docker-desktop -u root sysctl -w vm.max_map_count=262144

# 4) Khởi động
docker compose up -d

# 5) Kiểm tra
docker compose ps
```

Truy cập Dashboard: `https://localhost`  
Đăng nhập: `admin` / `123456`  
(Trình duyệt cảnh báo certificate tự ký — chọn Advanced → Continue.)

## 7.4. Cài Wazuh Agent trên Windows

1. Tải MSI agent cùng major version với manager từ tài liệu/packages Wazuh.
2. Cài đặt, trỏ **Manager IP** = IP máy Docker host (thường IP LAN hoặc `host.docker.internal` tùy topology).
3. Trên Dashboard: **Agent management → Summary** kiểm tra agent **Active**.

Hoặc dùng agent container (phù hợp demo log, hạn chế FIM host):

```yaml
environment:
  - WAZUH_MANAGER_SERVER=<IP_MANAGER>
```

## 7.5. Cấu hình FIM mẫu (Linux agent)

Trong `ossec.conf` của agent:

```xml
<syscheck>
  <directories check_all="yes" realtime="yes">/etc</directories>
  <directories check_all="yes" realtime="yes">/tmp/wazuh-lab</directories>
</syscheck>
```

Restart agent sau khi sửa.

## 7.6. Nạp luật tùy chỉnh trên Manager (Docker)

```powershell
docker cp lab\rules\local_rules.xml single-node-wazuh.manager:/var/ossec/etc/rules/local_rules.xml
docker exec -it single-node-wazuh.manager bash -c "/var/ossec/bin/wazuh-control restart"
```

*(Tên container có thể khác — kiểm tra bằng `docker ps`.)*

---

# CHƯƠNG 8. THỬ NGHIỆM CÁC KỊCH BẢN PHÁT HIỆN

> Thực hiện trong môi trường lab do nhóm tự quản lý. Không nhắm mục tiêu hệ thống bên ngoài.

## 8.1. Kịch bản 1 — Agent online và sự kiện cơ bản

**Mục tiêu:** Xác nhận pipeline Agent → Server → Indexer → Dashboard hoạt động.

**Các bước:**
1. Đăng nhập Dashboard.
2. Vào Agents, xác nhận trạng thái Active.
3. Quan sát Security events có event heartbeat / log thông thường.

**Kết quả mong đợi:** Agent hiển thị Connected/Active; có event mới.

*(Chèn Hình 8.1 — Agent Summary)*

## 8.2. Kịch bản 2 — Giám sát toàn vẹn tệp (FIM)

**Mục tiêu:** Phát hiện tạo/sửa/xóa file trong thư mục giám sát.

**Các bước (Linux agent ví dụ):**
```bash
mkdir -p /tmp/wazuh-lab
echo "hello" > /tmp/wazuh-lab/test.txt
echo "changed" >> /tmp/wazuh-lab/test.txt
rm /tmp/wazuh-lab/test.txt
```

Trên Windows agent: giám sát một thư mục lab (ví dụ `C:\wazuh-lab`) qua cấu hình FIM tương đương.

**Kết quả mong đợi:** Alert FIM (rule mặc định khoảng 550/553/554 tùy hành vi). Lọc Dashboard theo `rule.groups:syscheck` hoặc module FIM.

*(Chèn Hình 8.2 — Alert FIM)*

## 8.3. Kịch bản 3 — Đăng nhập thất bại / brute-force SSH (nếu có Linux SSH)

**Mục tiêu:** Quan sát rule authentication failure và rule tương quan brute-force.

**Các bước an toàn trong lab:**
```bash
# Từ máy attacker lab, thử vài lần mật khẩu sai tới victim lab
ssh saiuser@<IP_VICTIM>
```

Hoặc dùng danh sách mật khẩu ngắn + công cụ trong lab nội bộ (không dùng vào máy thật trên Internet).

**Lọc gợi ý trên Dashboard:** `rule.id:(5551 OR 5712 OR 5763 OR 5710 OR 5716)`

*(Chèn Hình 8.3 — Alert SSH)*

## 8.4. Kịch bản 4 — Luật tùy chỉnh

**Mục tiêu:** Chứng minh nhóm tự tạo luật và kiểm thử.

1. Thêm rule ID `100100` nhận diện chuỗi `WAZUH_LAB_ALERT` trong log.
2. Chạy `wazuh-logtest` với dòng log giả lập.
3. Restart manager; ghi log thật trên endpoint được agent theo dõi.
4. Xác nhận alert `100100` trên Dashboard.

Nội dung luật mẫu nằm tại `lab/rules/local_rules.xml`.

*(Chèn Hình 8.4 — logtest + alert custom)*

## 8.5. Kịch bản 5 — Đăng nhập Windows thất bại (Event 4625)

**Mục tiêu:** Minh họa phát hiện authentication failure trên endpoint Windows (tương đương KB1 phía Linux).

**Các bước (máy lab có Wazuh Agent):**
```powershell
.\lab\scripts\run-scenarios.ps1 -Scenario win-auth-fail
```

Script gọi API `LogonUser` với user giả / mật khẩu sai trên **chính máy lab** (không quét mạng bên ngoài). Kỳ vọng: Security Event **4625** và alert nhóm `authentication_failed` trên Dashboard.

Lọc gợi ý: `data.win.system.eventID:4625`

*(Chèn Hình 8.5 — Alert Windows failed logon)*

## 8.6. Kịch bản 6 — Tạo tài khoản Windows (Event 4720)

**Mục tiêu:** Phát hiện tạo user local (dấu hiệu persistence); kèm custom rule **100130** (MITRE T1136).

**Các bước (PowerShell Administrator):**
```powershell
.\lab\scripts\run-scenarios.ps1 -Scenario win-create-user
```

Script tạo user tạm `wazuh_lab_demo`, chờ để Agent thu Event **4720**, rồi xóa user (Event **4726**).

Lọc gợi ý: `data.win.system.eventID:4720` hoặc `rule.id:100130`

*(Chèn Hình 8.6 — Alert tạo tài khoản Windows)*

## 8.7. Bảng tổng hợp kết quả

| Kịch bản | Thành công? | Rule/Module liên quan | Ghi chú |
|----------|-------------|------------------------|---------|
| Agent online | *(điền)* | Agent management | |
| FIM | *(điền)* | syscheck / 100120 (Win) | |
| SSH fail/BF | *(điền)* | sshd rules | Linux |
| Custom rule | *(điền)* | 100100 | |
| Win failed logon | *(điền)* | Event 4625 | Windows |
| Win create user | *(điền)* | Event 4720 / 100130 | Windows |

## 8.8. Nhận xét thử nghiệm

- Độ trễ alert thường vài giây đến vài chục giây tùy buffering.
- Certificate tự ký gây cảnh báo trình duyệt — bình thường trong lab.
- Cần đồng bộ **phiên bản agent ≈ manager**.
- False positive có thể xảy ra nếu threshold tương quan quá thấp.
- Trên Windows cần bật audit Logon / Account Management nếu không thấy Event 4625/4720.

---

# CHƯƠNG 9. ƯU ĐIỂM VÀ NHƯỢC ĐIỂM

## 9.1. Ưu điểm

1. **Mã nguồn mở**, cộng đồng và tài liệu lớn.  
2. **Đa tính năng** trên một nền tảng (FIM, SCA, Vuln, AR, Compliance…).  
3. **Agent đa nền tảng**, quản lý tập trung.  
4. **Ruleset phong phú**, dễ mở rộng bằng XML.  
5. Triển khai linh hoạt: VM, bare-metal, **Docker**, cloud.  
6. Dashboard trực quan phục vụ SOC/học tập.

## 9.2. Nhược điểm / hạn chế

1. **Tài nguyên:** Indexer + stack khá nặng RAM/CPU.  
2. **Đường cong học:** luật, decoder, tuning cần thời gian.  
3. **False positive** nếu chưa tinh chỉnh.  
4. Active Response cấu hình sai có thể gây gián đoạn dịch vụ.  
5. Không thay thế chuyên sâu NIDS/EDR thương mại trong mọi tình huống — cần kiến trúc phòng thủ nhiều lớp.

---

# CHƯƠNG 10. KẾT LUẬN

Báo cáo đã trình bày tổng quan nền tảng Wazuh với vai trò XDR/SIEM mã nguồn mở; phân tích kiến trúc Agent–Server–Indexer–Dashboard và luồng xử lý sự kiện; mô tả các thành phần, cổng giao tiếp và cơ chế decode/rule/alert; hệ thống hóa tính năng chính cùng quy trình tạo, ghi đè và kiểm thử luật; đồng thời thực hiện cài đặt lab Docker single-node và thử nghiệm các kịch bản FIM, đăng nhập thất bại và luật tùy chỉnh.

Qua thực nghiệm, nhóm nhận thấy Wazuh phù hợp để xây dựng năng lực giám sát bảo mật cơ bản, hỗ trợ học tập sâu về log analysis và detection engineering. Hướng phát triển tiếp theo có thể gồm: Active Response tự động chặn IP, tích hợp Suricata, triển khai multi-node HA, và viết bộ luật bám sát dịch vụ đặc thù của tổ chức.

---

# TÀI LIỆU THAM KHẢO

[1] Wazuh Inc., “Architecture – Getting started with Wazuh,” Wazuh documentation.  
https://documentation.wazuh.com/current/getting-started/architecture.html  

[2] Wazuh Inc., “Components – Getting started with Wazuh,” Wazuh documentation.  
https://documentation.wazuh.com/current/getting-started/components/index.html  

[3] Wazuh Inc., “Wazuh Docker deployment,” Wazuh documentation.  
https://documentation.wazuh.com/current/deployment-options/docker/wazuh-container.html  

[4] Wazuh Inc., “Custom rules,” Wazuh documentation.  
https://documentation.wazuh.com/current/user-manual/ruleset/rules/custom.html  

[5] Wazuh Inc., “Creating custom FIM rules,” Wazuh documentation.  
https://documentation.wazuh.com/current/user-manual/capabilities/file-integrity/creating-custom-fim-rules.html  

[6] Wazuh Inc., “Detecting a brute-force attack – Proof of Concept guide,” Wazuh documentation.  
https://documentation.wazuh.com/current/proof-of-concept-guide/detect-brute-force-attack.html  

[7] Wazuh Inc., “Blocking SSH brute-force attack with Active Response,” Wazuh documentation.  
https://documentation.wazuh.com/current/user-manual/capabilities/active-response/ar-use-cases/blocking-ssh-brute-force.html  

[8] Wazuh GitHub, “wazuh-docker,” repository.  
https://github.com/wazuh/wazuh-docker  

---

# PHỤ LỤC

## Phụ lục A. Outline thuyết trình (2–3 phút/người)

**TV1:** Bối cảnh IDS/SIEM → Wazuh là gì → Hình kiến trúc → kết nối sang thành phần.  
**TV2:** 4 thành phần + cổng + pipeline decode/rule/alert.  
**TV3:** Tính năng nổi bật + cấu trúc luật + demo logtest/custom rule.  
**TV4:** Cách cài Docker lab + 2–3 ảnh kết quả kịch bản + ưu/nhược + kết luận.

## Phụ lục B. Checklist nộp bài

- [ ] Đủ tên thành viên trên trang bìa  
- [ ] ~25–30 trang, đủ mục bắt buộc  
- [ ] Ảnh lab có chú thích  
- [ ] Tài liệu tham khảo  
- [ ] File PDF đặt tên: `NOS – 2025-2 - Nhóm 5.pdf`  
- [ ] Mỗi người luyện nói 2–3 phút  

## Phụ lục C. Lệnh vận hành nhanh

```powershell
cd lab\wazuh-docker\single-node
docker compose ps
docker compose logs -f wazuh.manager
docker compose restart
docker compose down
```
