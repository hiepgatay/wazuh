# Lab Wazuh — Hướng dẫn cài đặt & thử nghiệm (Nhóm 5)

Môi trường khuyến nghị: **Windows 10/11 + Docker Desktop (WSL2)**  
Stack: **single-node** tag `v4.14.8`

## 0. Kiểm tra trước khi chạy

- RAM ≥ 8 GB (ít nhất 12–16 GB trống khi chạy stack)
- Docker Desktop đang **Running**
- Cổng 443, 1514, 1515, 55000, 9200 chưa bị chiếm

```powershell
docker version
docker compose version
```

## 1. Cấu hình vm.max_map_count (bắt buộc)

Trong PowerShell **Admin** hoặc cửa sổ thường:

```powershell
wsl -d docker-desktop -u root sysctl -w vm.max_map_count=262144
```

Nếu lệnh lỗi (distro tên khác), mở **Docker Desktop → Settings → Resources → WSL Integration** rồi thử lại. Có thể thêm vào `%UserProfile%\.wslconfig`:

```ini
[wsl2]
kernelCommandLine = sysctl.vm.max_map_count=262144
```

Sau đó: `wsl --shutdown` và mở lại Docker Desktop.

## 2. Khởi động Wazuh Manager stack

Repo đã clone tại `lab/wazuh-docker` (nếu chưa có, chạy script).

```powershell
cd "c:\Users\Dell P7730\Downloads\HĐH mạng\lab\wazuh-docker\single-node"

# Sinh chứng chỉ (chỉ lần đầu)
docker compose -f generate-indexer-certs.yml run --rm generator

# Chạy stack
docker compose up -d

# Theo dõi
docker compose ps
docker compose logs -f wazuh.dashboard
```

Đợi 1–3 phút đến khi Dashboard sẵn sàng.

## 3. Đăng nhập Dashboard

- URL: https://localhost  
- User: `admin`  
- Pass: `123456`  

Chấp nhận cảnh báo chứng chỉ tự ký.

## 4. Cài Agent (chọn một)

### 4.A Agent Windows (khuyến nghị cho demo FIM trên máy thật)

1. Tải agent cùng dòng 4.14.x: https://documentation.wazuh.com/current/installation-guide/wazuh-agent/wazuh-agent-package-windows.html  
2. Manager address = IP máy host (ipconfig) hoặc `127.0.0.1` nếu agent và port publish local.  
3. Sau cài: Services → `Wazuh` Running.  
4. Dashboard → Agents → thấy agent Active.

### 4.B Agent container (nhanh, hạn chế giám sát host)

```powershell
cd "..\wazuh-agent"
# Sửa WAZUH_MANAGER_SERVER trong docker-compose.yml = host.docker.internal hoặc IP host
docker compose up -d
```

## 5. Nạp luật tùy chỉnh

```powershell
cd "c:\Users\Dell P7730\Downloads\HĐH mạng"
$mgr = (docker ps --format "{{.Names}}" | Select-String "wazuh.manager").ToString()
docker cp ".\lab\rules\local_rules.xml" "${mgr}:/var/ossec/etc/rules/local_rules.xml"
docker exec $mgr /var/ossec/bin/wazuh-control restart
```

Kiểm thử:

```powershell
docker exec -it $mgr /var/ossec/bin/wazuh-logtest
# Dán: Jan 1 12:00:00 testhost app: WAZUH_LAB_ALERT test message
```

## 6. Chạy kịch bản

Hướng dẫn demo chi tiết (KB1–KB6): **`lab/HUONG-DAN-DEMO-KICH-BAN.md`**

```powershell
.\lab\scripts\run-scenarios.ps1 -Scenario status
.\lab\scripts\run-scenarios.ps1 -Scenario load-rules
.\lab\scripts\run-scenarios.ps1 -Scenario ssh -Target <IP_VICTIM>
.\lab\scripts\run-scenarios.ps1 -Scenario fim
.\lab\scripts\run-scenarios.ps1 -Scenario system-file
.\lab\scripts\run-scenarios.ps1 -Scenario custom-log
.\lab\scripts\run-scenarios.ps1 -Scenario win-auth-fail
.\lab\scripts\run-scenarios.ps1 -Scenario win-create-user   # Admin
```

Script: `kb1`–`kb4` (bash), `kb5-win-failed-logon.ps1`, `kb6-win-create-user.ps1`.  
Báo cáo tổng hợp: `bao-cao` Chương 8.

## 7. Chụp ảnh minh họa báo cáo

Lưu vào `lab/screenshots/`:

1. `01-dashboard-login.png`
2. `02-agents-active.png`
3. `03-fim-alert.png`
4. `04-custom-rule-alert.png`
5. `05-ssh-or-auth-fail.png` (nếu có)
6. `06-system-file-alert.png` (nếu có)
7. `07-win-auth-fail.png` (Windows 4625)
8. `08-win-create-user.png` (Windows 4720)

## 8. Dừng lab

```powershell
cd "lab\wazuh-docker\single-node"
docker compose down
# Xóa volume (mất data): docker compose down -v
```

## Xử lý lỗi thường gặp

| Triệu chứng | Cách xử lý |
|-------------|------------|
| Indexer crash / max virtual memory | Set `vm.max_map_count=262144` rồi `docker compose restart` |
| Dashboard “not ready yet” | Đợi thêm; xem `docker compose logs wazuh.indexer` |
| Agent never connect | Kiểm tra firewall, đúng IP:1514/1515, version agent |
| Port 443 in use | Đổi map port trong docker-compose.yml (ví dụ `8443:5601`) |
