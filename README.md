# NOS 2025-2 — Nhóm 5: Wazuh

Đề tài: **Hệ thống phát hiện tấn công, xâm nhập Wazuh**

## Cấu trúc thư mục

| Thư mục / file | Nội dung |
|----------------|----------|
| `bao-cao/00-PHAN-CONG-NHOM.md` | Phân công 4 thành viên |
| `bao-cao/BAO-CAO-WAZUH-NOS-2025-2-Nhom-5.md` | **Bản thảo báo cáo đầy đủ** (chuyển Word/PDF) |
| `bao-cao/01-OUTLINE-THUYET-TRINH.md` | Outline nói 2–3 phút/người |
| `lab/HUONG-DAN-CAI-DAT.md` | Cài Docker + agent + xử lý lỗi |
| `lab/rules/local_rules.xml` | Luật tùy chỉnh lab |
| `lab/scripts/run-scenarios.ps1` | Script hỗ trợ thử nghiệm |
| `lab/wazuh-docker/` | Repo official Wazuh Docker (v4.14.8) |
| `lab/screenshots/` | Chụp ảnh Dashboard để chèn báo cáo |

## Việc cần làm ngay

1. Đợi `docker compose up -d` xong (lần đầu tải image khá lâu).
2. Mở https://localhost → `admin` / `123456`
3. Cài Agent Windows + chạy kịch bản trong `lab/HUONG-DAN-CAI-DAT.md`
4. Điền tên 4 thành viên vào trang bìa báo cáo
5. Xuất PDF tên: **`NOS – 2025-2 - Nhóm 5.pdf`**

## Lệnh nhanh

```powershell
cd "lab\wazuh-docker\single-node"
docker compose ps
docker compose logs --tail 50 wazuh.manager
```
