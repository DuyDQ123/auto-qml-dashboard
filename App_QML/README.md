# Bảng Điều Khiển Xe Hơi (Car Dashboard)

## Tổng Quan
Đây là ứng dụng mô phỏng bảng điều khiển xe hơi được phát triển bằng Qt/QML. Ứng dụng cung cấp giao diện hiện đại với đồng hồ tốc độ kỹ thuật số, các đèn báo và các chỉ số theo dõi khác của xe.

## Cấu Trúc Project
```
ProjectFinal/
├── main.cpp              # Entry point của ứng dụng
├── main.qml              # Giao diện chính
├── Gauge.qml             # Component đồng hồ tốc độ chính
├── SideGauge.qml         # Component đồng hồ phụ
├── radialbar.h/cpp       # Component thanh tiến trình hình tròn
├── assets/               # Thư mục chứa hình ảnh và icon
└── img/                  # Thư mục chứa các tài nguyên hình ảnh khác
```

## Các Tính Năng Chính

### 1. Đồng Hồ Tốc Độ Chính
- Hiển thị tốc độ hiện tại dạng số và kim đồng hồ
- Màu sắc thay đổi theo tốc độ:
  - Xanh lá: < 60 MPH
  - Vàng: 60-150 MPH
  - Đỏ: > 150 MPH

### 2. Các Đèn Báo
- Đèn pha (Low beam headlights)
- Đèn sương mù (Rare fog lights)
- Đèn đỗ xe (Parking lights)
- Đèn cảnh báo
- Đèn dây an toàn

### 3. Thông Tin Hiển Thị
- Hiển thị thời gian thực
- Hiển thị ngày tháng
- Chỉ số giới hạn tốc độ
- Trạng thái hộp số (P/R/N/D)

### 4. Các Đồng Hồ Phụ
- Đồng hồ bên trái và phải với giao diện gradient
- Hiển thị các thông số phụ của xe

## Hướng Dẫn Cài Đặt

1. Yêu cầu hệ thống:
   - Qt 5.15 trở lên
   - Qt Quick và Qt Quick Controls 2
   - Compiler hỗ trợ C++11

2. Các bước cài đặt:
   ```bash
   # Clone repository
   git clone <repository-url>
   
   # Di chuyển vào thư mục project
   cd ProjectFinal
   
   # Chạy qmake
   qmake
   
   # Build project
   make
   ```

## Hướng Dẫn Sử Dụng

### Điều Khiển Bàn Phím:
- **Phím Space**: Giữ để tăng tốc đồng hồ tốc độ chính từ 0 đến 250 MPH. Thả ra để giảm về 0.
- **Phím Enter/Return**: Giữ để tăng giá trị thanh pin từ 0% đến 100%. Thả ra để giảm về giá trị mặc định.
- **Phím mũi tên trái**: Giữ để tăng giá trị đồng hồ phụ bên trái từ 0 đến 250. Thả ra để giảm về 0.
- **Phím mũi tên phải**: Giữ để tăng giá trị đồng hồ phụ bên phải từ 0 đến 250. Thả ra để giảm về 0.
- **Phím M**: Bật/tắt đèn cảnh báo thứ 4 bên phải (chuyển đổi giữa màu mặc định và màu đỏ)
- **Phím L**: Bật/tắt đèn sương mù phía sau (chuyển đổi giữa màu mặc định và màu đỏ)
- **Phím N**: Bật/tắt đèn pha (chuyển đổi giữa trạng thái bật và tắt)
- **Phím B**: Bật/tắt đèn chính (chuyển đổi giữa màu trắng và màu mặc định)
- **Phím C**: Bật/tắt đèn đỗ xe (chuyển đổi giữa trạng thái bật và tắt)
- **Phím V**: Bật/tắt cảnh báo dây an toàn (chuyển đổi giữa màu xám và màu mặc định)
- **Phím Z**: Bật/tắt đèn cảnh báo thứ 2 bên phải (chuyển đổi giữa màu mặc định và màu đỏ)
- **Phím X**: Bật/tắt đèn cảnh báo thứ 3 bên phải (chuyển đổi giữa màu mặc định và màu đỏ)
- **Phím tắt Ctrl+Q**: Thoát khỏi ứng dụng

### Điều Khiển Chuột:
- Click vào các biểu tượng đèn để bật/tắt
- Tương tác với các thành phần UI khác nhau

## Ghi Chú
- Ứng dụng hỗ trợ màn hình độ phân giải 1920x960
- Giao diện được tối ưu hóa với màu nền tối (#1E1E1E)
- Các thành phần UI được thiết kế với animation mượt mà
