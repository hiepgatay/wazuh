# Kịch bản tấn công & phòng thủ Windows (lab)

Lab này bám theo phần Windows trong báo cáo *An toàn thông tin nâng cao*: chuỗi kiểu **phishing → WinRAR → shell → file trong Temp → kết nối ra ngoài**, đối chiếu với **Sysmon + Wazuh rule + Active Response**.

> **Phạm vi an toàn:** lab chỉ **mô phỏng hành vi tiến trình** bằng `echo`, `ping 127.0.0.1`, `hostname.exe`.  
> Không tạo malware, file RAR khai thác CVE-2023-38831, reverse shell, Metasploit payload hay keylogger.  
> Phòng thủ thật với CVE WinRAR: cập nhật WinRAR lên **6.23 trở lên**.

---

## 1. Mô hình lab

| Máy | Vai trò trong báo cáo | Trong lab của bạn |
|-----|------------------------|-------------------|
| Attacker (Kali) | Gửi mail / handler | Không dựng — thay bằng script mô phỏng trên victim |
| Victim (Windows) | Agent + WinRAR cũ | Windows + **Wazuh Agent** + **Sysmon** |
| SOC (Ubuntu/Docker) | Manager + Dashboard | Docker `single-node` (đã có sẵn trong repo) |

```
[ Mô phỏng tấn công trên Windows ]
   WinRAR.exe (bản sao cmd đặt tên)  -->  cmd.exe  -->  file trong %TEMP%\wazuh-lab-att
                         |
                    Sysmon Event 1
                         |
                   Wazuh Agent
                         |
                   Wazuh Manager  -->  rule 100010 / 100011
                         |
                   Active Response  -->  kill_malware.cmd (tắt đúng PID)
```

---

## 2. Ánh xạ báo cáo → lab

| Bước trong báo cáo | MITRE | Lab làm gì | Blue Team |
|--------------------|-------|------------|-----------|
| Phishing + file RAR | T1566 | Không mô phỏng gửi mail | Giả định nạn nhân đã “mở” file |
| CVE-2023-38831 kích hoạt | T1203 | Không dựng exploit | Cập nhật WinRAR ≥ 6.23 |
| WinRAR gọi `cmd.exe` | T1059 / T1204 | Script tạo cây `WinRAR.exe` → `cmd.exe` | **Rule 100010** |
| Chạy file trong Temp | T1059 / T1204 | `cmd` chạy `hostname.exe` trong `%TEMP%\wazuh-lab-att` | **Rule 100011** |
| Reverse shell / C2 | T1071 | Không mở kết nối ra ngoài | **Rule 100012** (chỉ khi có Event Sysmon 3 thật) |
| Keylogger | T1056 | Không triển khai | Ngoài phạm vi lab này |
| Ngăn chặn | — | `kill_malware.cmd` / `.ps1` | Active Response khi **100010** hoặc **100011** |

---

## 3. Thành phần đã có trong repo

| Đường dẫn | Việc |
|-----------|------|
| `lab/rules/local_rules.xml` | Rule **100010**, **100011**, **100012** |
| `lab/config/sysmonconfig-lab.xml` | Sysmon tối thiểu (ProcessCreate + NetworkConnect) |
| `lab/config/manager-ar-winrar-snippet.xml` | Khai báo Active Response trên Manager |
| `lab/scripts/active-response/kill_malware.cmd` | Wrapper AR |
| `lab/scripts/active-response/kill_malware.ps1` | Tắt đúng PID trong alert (có kiểm tra path) |
| `lab/scripts/kb7-win-sysmon-sim.ps1` | Setup + mô phỏng tấn công |
| `lab/scripts/win-attack-defense.ps1` | Orchestrator: Prepare / Attack / Status |
| `lab/scripts/run-scenarios.ps1` | `-Scenario win-winrar-setup` / `win-winrar` |

---

## 4. Chuẩn bị (một lần) — PowerShell **Admin**

```powershell
cd "c:\Users\Dell P7730\Downloads\HĐH mạng"

# 1) Stack Wazuh đang chạy + Agent Active trên Dashboard
.\lab\scripts\run-scenarios.ps1 -Scenario status

# 2) Cài Sysmon, gắn kênh vào Agent, chép AR, cấu hình Manager
.\lab\scripts\win-attack-defense.ps1 -Phase Prepare

# 3) Nạp luật
.\lab\scripts\run-scenarios.ps1 -Scenario load-rules
```

`Prepare` sẽ:

1. Tải Sysmon (Sysinternals) vào `C:\wazuh-lab\tools` nếu chưa có (đường dẫn ASCII, tránh lỗi tên thư mục tiếng Việt).
2. Cài / áp cấu hình `sysmonconfig-lab.xml`.
3. Thêm `Microsoft-Windows-Sysmon/Operational` vào `ossec.conf` của Agent.
4. Chép `kill_malware.*` vào `active-response\bin`.
5. Thêm Active Response trên container Manager (nếu Docker đang chạy).

---

## 5. Demo giống báo cáo (khuyến nghị thuyết trình)

**Không cần script Attack.** Dùng case tay: mail HTML + RAR + WinRAR thật.

Chi tiết từng bước: [`lab/demo-windows-case/HUONG-DAN-DEMO-GIONG-BAO-CAO.md`](demo-windows-case/HUONG-DAN-DEMO-GIONG-BAO-CAO.md)

Tóm tắt:

1. Mở `lab/demo-windows-case/phishing-mail.html`
2. Mở `lab/demo-windows-case/out/Thong_bao_LAB.rar` bằng WinRAR
3. Trong WinRAR, **double-click** `MO_LAB_kich_hoat.cmd` (PDF mở + lệnh vô hại)
4. Dashboard: `rule.id:(100010 OR 100011)`

> RAR thường, không CVE. Click `.cmd` trong WinRAR tạo đúng cây `WinRAR.exe → cmd.exe` để rule 100010 bắt.

### (Tuỳ chọn) Mô phỏng bằng script

```powershell
.\lab\scripts\win-attack-defense.ps1 -Phase Attack
```

---

## 6. Kiểm tra phòng thủ

### Dashboard

https://localhost — `admin` / `123456`

Threat Hunting:

```
rule.id:(100010 OR 100011 OR 100012)
```

```
rule.groups:att_win
```

### Event Viewer (máy victim)

*Applications and Services Logs → Microsoft → Windows → Sysmon → Operational*  
Event ID **1** (Process Create), ParentImage kết thúc bằng `WinRAR.exe`.

### Active Response

```
C:\wazuh-lab\active-response.log
```

---

## 7. Checklist thuyết trình

| # | Việc | OK |
|---|------|----|
| 1 | Agent Windows Active | ☐ |
| 2 | Sysmon service đang chạy | ☐ |
| 3 | Đã `load-rules` (100010–100012) | ☐ |
| 4 | Chạy `-Phase Attack` | ☐ |
| 5 | Dashboard hiện **100010** | ☐ |
| 6 | Dashboard hiện **100011** | ☐ |
| 7 | (Tuỳ chọn) log Active Response | ☐ |
| 8 | Nói rõ: lab mô phỏng hành vi; vá WinRAR ≥ 6.23 | ☐ |

Screenshot gợi ý: `lab/screenshots/09-win-winrar-sysmon.png`

---

## 8. Lỗi thường gặp

| Triệu chứng | Cách xử lý |
|-------------|------------|
| Không có 100010 | Chưa cài Sysmon / chưa Admin Prepare / Agent chưa đọc Sysmon channel |
| Sysmon lỗi mở XML | Dùng Prepare (copy config sang `C:\wazuh-lab\tools\…`) |
| Có 100010 nhưng không kill | Chưa chép `kill_malware.*` hoặc chưa AR trên Manager → chạy lại Prepare + `load-rules` |
| Quá nhiều 100011 | Rule bắt mọi file trong Temp do shell; tắt demo xong có thể comment rule trong `local_rules.xml` rồi `load-rules` lại |

---

## 9. Lời thuyết trình ngắn

> “Chuỗi tấn công trong báo cáo dựa trên phishing và lỗi WinRAR cũ. Trong lab chúng em không dựng exploit hay reverse shell. Em mô phỏng đúng hành vi mà SOC cần bắt: WinRAR đẻ ra cmd, rồi shell chạy file trong Temp. Sysmon ghi Process Create, Wazuh rule 100010/100011 cảnh báo, Active Response tắt đúng PID trong alert. Biện pháp gốc vẫn là cập nhật WinRAR và không mở file đính kèm lạ.”
