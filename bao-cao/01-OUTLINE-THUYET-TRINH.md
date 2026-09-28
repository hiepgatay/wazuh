# Kịch bản thử nghiệm nhanh — copy vào báo cáo / thuyết trình

## TV4 nói trong 2–3 phút (gợi ý lời thoại)

1. “Nhóm triển khai Wazuh single-node bằng Docker: Manager, Indexer, Dashboard.”
2. “Agent kết nối thành công, trạng thái Active trên Dashboard.”
3. “Kịch bản FIM: tạo/sửa/xóa file → alert syscheck.”
4. “Kịch bản luật tùy chỉnh ID 100100: chuỗi WAZUH_LAB_ALERT.”
5. “Kết luận: pipeline phát hiện hoạt động; ưu điểm mã mở & ruleset; hạn chế tài nguyên và cần tuning.”

## Checklist kết quả

- [ ] https://localhost đăng nhập được
- [ ] ≥ 1 agent Active
- [ ] Có alert FIM
- [ ] Có alert rule 100100
- [ ] (Tuỳ chọn) alert SSH fail

## Lọc Dashboard hữu ích

```
rule.id:100100
rule.groups:syscheck
rule.id:(5710 OR 5716 OR 5763 OR 5551 OR 5712)
```
