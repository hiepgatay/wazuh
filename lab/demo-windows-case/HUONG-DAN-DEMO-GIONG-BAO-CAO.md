# Demo case Windows giống báo cáo (không dùng script mô phỏng)

Case này **đóng vai** chuỗi trong báo cáo ATTT: mail phishing → file RAR → WinRAR → `cmd` → Wazuh phát hiện / Active Response.

> **An toàn:** RAR **thường** (không CVE-2023-38831). File `.cmd` chỉ mở PDF lab, chạy `hostname` và `ping 127.0.0.1`.  
> Không malware, không reverse shell, không keylogger.  
> Trong báo cáo: click PDF trên WinRAR cũ có thể tự chạy mã độc — lab **cố ý** để bạn double-click `MO_LAB_kich_hoat.cmd` trong WinRAR để có **cùng hành vi** `WinRAR.exe → cmd.exe` mà SOC bắt được.

---

## File đã chuẩn bị

| File | Vai trò giống báo cáo |
|------|------------------------|
| `phishing-mail.html` | Mail lừa đảo (mở bằng trình duyệt) |
| `out/Thong_bao_LAB.rar` | File đính kèm |
| `payload-lab/*.pdf` | File mồi PDF (đã sửa cấu trúc) |
| `payload-lab/*.html` | File mồi dự phòng nếu PDF báo lỗi trên máy |
| `payload-lab/MO_LAB_kich_hoat.cmd` | “Script kích hoạt” vô hại |
| Cùng bản tại `C:\wazuh-lab\demo-case\` | Đường dẫn ASCII, dễ mở |

---

## Điều kiện Blue Team (trước khi lên sân)

1. Wazuh Dashboard: https://localhost — Agent Windows **Active**
2. Sysmon đang chạy; Agent đọc `Microsoft-Windows-Sysmon/Operational`
3. Đã nạp rule **100010 / 100011 / 100012** và Active Response `kill_malware`

Nếu chưa Prepare: chuột phải `C:\wazuh-lab\tools\CHAY-PREPARE-ADMIN.cmd` → Run as administrator.

---

## Kịch bản thuyết trình (tay, giống báo cáo)

### Bước 0 — SOC (1 phút)

- Mở Dashboard → Agents → máy bạn Active  
- Threat Hunting, filter sẵn: `rule.groups:att_win` · Last 15 minutes  

### Bước 1 — “Gửi / nhận mail” (Red)

1. Mở `phishing-mail.html` (đã giống hình mail trong báo cáo).  
2. Nói: nạn nhân tải file đính kèm `Thong_bao_LAB.rar`.  
3. Mở RAR bằng **WinRAR thật** (không giải nén ra Explorer nếu muốn parent = WinRAR).

### Bước 2 — “Mở file trong WinRAR” (Red)

1. Trong cửa sổ WinRAR thấy PDF + `MO_LAB_kich_hoat.cmd`.  
2. **Double-click** `MO_LAB_kich_hoat.cmd` (trong WinRAR).  
3. PDF lab mở ra; phía dưới chạy hostname / ping loopback (cửa sổ có thể tắt nhanh nếu AR kill).

Đây là chỗ tương đương “script thực thi khi click file mồi” trong báo cáo — nhưng an toàn.

### Bước 3 — Phòng thủ (Blue)

**Phát hiện (bắt buộc để demo):**

1. Dashboard: alert **100010** — WinRAR tạo cmd.  
2. Có thể có **100011** — chạy file trong Temp.  

**Phản ứng Active Response (log kill):**

3. File `C:\wazuh-lab\active-response.log`  
   - Có dòng `START` / `da tat PID` → AR đã chạy.  
   - Chỉ có `FILE_TAO_BOI_LAB` hoặc không có file → Wazuh chưa gọi script (vẫn demo được phần phát hiện).  
4. Chuột phải `C:\wazuh-lab\tools\CAI-AR-ADMIN.cmd` → Run as administrator (một lần), rồi lặp lại double-click `.cmd` trong WinRAR.  
5. (Tuỳ chọn) Event Viewer → Sysmon → Event ID 1, ParentImage `...\WinRAR.exe`.

### Bước 4 — Kết luận

> “Báo cáo dùng CVE WinRAR + payload. Lab tái hiện **đúng chuỗi hành vi** WinRAR→cmd trên WinRAR thật để Wazuh/Sysmon bắt. Biện pháp gốc: không mở đính kèm lạ, cập nhật WinRAR ≥ 6.23.”

---

## Checklist

| # | Việc | OK |
|---|------|----|
| 1 | Mở mail HTML | ☐ |
| 2 | Mở RAR bằng WinRAR | ☐ |
| 3 | Double-click `MO_LAB_kich_hoat.cmd` trong WinRAR | ☐ |
| 4 | Dashboard **100010** | ☐ |
| 5 | (Tuỳ chọn) AR log / 100011 | ☐ |

---

## Không làm gì trong demo này

- Không tạo / không chạy Metasploit reverse shell  
- Không dựng RAR CVE-2023-38831  
- Không cài keylogger  
- Không cần `win-attack-defense.ps1 -Phase Attack` (đó là mô phỏng script; case này dùng WinRAR tay)
