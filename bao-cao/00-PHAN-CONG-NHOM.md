# Phân công Nhóm 5 — Hệ thống phát hiện tấn công, xâm nhập Wazuh

**Môn:** Hệ điều hành mạng (NOS) — Học kỳ 2025-2  
**Tên file nộp:** `NOS – 2025-2 - Nhóm 5.pdf`  
**Độ dài báo cáo:** khoảng 25–30 trang  
**Thuyết trình:** mỗi thành viên 2–3 phút

---

## Tổng quan phân công

| Thành viên | Vai trò ngắn | Phần báo cáo chính | Lab thực hành | Thời lượng trình bày |
|---|---|---|---|---|
| **TV1** | Giới thiệu & kiến trúc | Trang bìa, Mục lục, Ch.1–2 | Hỗ trợ thiết kế sơ đồ | 2–3 phút |
| **TV2** | Thành phần & cơ chế | Ch.3–4 | Cài Manager/Indexer/Dashboard | 2–3 phút |
| **TV3** | Luật & tính năng | Ch.5–6 | Viết luật tùy chỉnh + logtest | 2–3 phút |
| **TV4** | Cài đặt, thử nghiệm, kết luận | Ch.7–9, Kết luận, Tài liệu TK | Agent + chạy kịch bản phát hiện | 2–3 phút |

> Điền tên thật vào trang bìa và bảng trên trước khi xuất PDF.

---

## Chi tiết từng thành viên

### TV1 — Giới thiệu & kiến trúc (~6–7 trang)
- Bối cảnh an ninh mạng, IDS/IPS/SIEM/XDR
- Wazuh là gì, lịch sử ngắn (fork OSSEC → nền tảng XDR/SIEM mã nguồn mở)
- Mục tiêu, phạm vi báo cáo
- Kiến trúc tổng thể: Agent → Server → Indexer → Dashboard
- Các mô hình triển khai: All-in-one, Single-node, Multi-node
- Sơ đồ kiến trúc (vẽ bằng draw.io / PowerPoint)

**Slide nói (2–3 phút):** “Wazuh giải quyết bài toán gì? Luồng dữ liệu đi như thế nào?”

### TV2 — Thành phần & cơ chế hoạt động (~7–8 trang)
- Chi tiết 4 thành phần: Agent, Server (Manager + Analysis Engine), Indexer, Dashboard
- Cổng mạng quan trọng (1514, 1515, 55000, 9200, 443)
- Cơ chế: thu thập → decode → rule matching → alert → index → visualize
- Agentless (Syslog), mã hóa AES
- Ưu / nhược điểm (phần đầu)

**Slide nói:** “Mỗi thành phần làm gì? Alert được sinh ra bằng cách nào?”

### TV3 — Tính năng, luật & tạo luật (~7–8 trang)
- Các tính năng: FIM, SCA, Vulnerability Detection, Malware/Rootkit, Active Response, Compliance…
- Ruleset mặc định, mức độ (level 0–15)
- Cấu trúc luật XML, ID tùy chỉnh ≥ 100000
- Cách tạo/ghi đè luật, dùng `wazuh-logtest`
- Ví dụ luật nhóm (file nhạy cảm, đăng nhập thất bại…)

**Slide nói:** “Luật Wazuh hoạt động ra sao? Demo 1 luật tùy chỉnh.”

### TV4 — Cài đặt, thử nghiệm, kết luận (~7–8 trang)
- Yêu cầu phần cứng/phần mềm
- Cài Docker single-node + Agent Windows/Linux
- Kịch bản thử nghiệm (ảnh chụp Dashboard)
- Ưu/nhược điểm (tóm tắt cuối)
- Kết luận + Tài liệu tham khảo
- Phụ lục lệnh / cấu hình

**Slide nói:** “Lab đã cài gì? Kết quả 2–3 kịch bản phát hiện.”

---

## Lịch làm việc đề xuất (1 tuần)

| Ngày | Việc |
|---|---|
| Ngày 1–2 | TV2 + TV4 cài lab Docker; TV1 vẽ sơ đồ; TV3 đọc ruleset |
| Ngày 3–4 | Chạy đủ kịch bản, chụp ảnh; viết draft từng chương |
| Ngày 5 | Gộp báo cáo, thống nhất thuật ngữ, format |
| Ngày 6 | Xuất PDF đúng tên file; luyện thuyết trình |
| Ngày 7 | Dự phòng sửa theo góp ý |

---

## Quy ước viết báo cáo

- Font: Times New Roman 13 (hoặc theo mẫu GV), lề chuẩn, cách dòng 1.5
- Hình/ảnh có chú thích: *Hình x.y – Mô tả*
- Bảng có tiêu đề: *Bảng x.y – Mô tả*
- Trích dẫn số trong ngoặc vuông [1], khớp Mục Tài liệu tham khảo
- Không copy nguyên văn tài liệu tiếng Anh dài; tóm tắt bằng tiếng Việt
