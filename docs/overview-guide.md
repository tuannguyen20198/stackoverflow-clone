🏗️ Mô tả hoạt động hệ thống với API Gateway & OpenAPI JSON
1️⃣ Kiến trúc tổng quan
backend/
├── api-gateway/        # Cổng trung gian, entrypoint của tất cả request
├── user-service/       # Dịch vụ quản lý người dùng
├── post-service/       # Dịch vụ quản lý bài viết
├── payment-service/    # Dịch vụ thanh toán
└── ...                 # Các service khác


API Gateway là điểm entry duy nhất cho client (FE/Mobile/Postman).

Mỗi microservice có file openapi.json mô tả endpoint, input/output schema.

Gateway tự động đọc và merge OpenAPI JSON của các service, sinh route tự động.

Client chỉ cần gọi các API thông qua gateway, không cần biết service nào xử lý.

2️⃣ Quy trình hoạt động chi tiết
🔹 Bước 1: Khởi động hệ thống
# Tại root repo
pnpm install
pnpm run dev


API Gateway start → lắng nghe port entry (ví dụ http://localhost:3000)

Mỗi service start → lắng nghe port riêng (user-service: 3001, post-service: 3002...)

🔹 Bước 2: Gateway nạp OpenAPI JSON

Gateway đọc danh sách service từ cấu hình.

Gửi request hoặc đọc file openapi.json của từng service.

Merge các OpenAPI JSON thành OpenAPI tổng hợp.

Dựa trên spec này, gateway sinh route tự động:

/users/*   → user-service
/posts/*   → post-service
/payments/* → payment-service

🔹 Bước 3: Client gửi request

Ví dụ: Client gọi GET /users/123

Gateway kiểm tra route /users/{id} trong OpenAPI tổng hợp.

Forward request tới user-service.

Service xử lý request, trả về JSON response.

Gateway nhận response → trả lại cho client.

✅ Lợi ích:

FE chỉ cần gọi gateway, không cần biết backend chi tiết.

Các service có thể scale / deploy độc lập.

OpenAPI đảm bảo type safety và auto-docs.

🔹 Bước 4: Thêm service mới

Service mới tạo openapi.json với các endpoint.

Cập nhật config gateway để include service mới.

Gateway tự động merge spec, sinh route mới mà không cần sửa code thủ công.

3️⃣ Minh họa flow bằng sơ đồ
flowchart LR
    subgraph CLIENT
        A[Frontend / Mobile / Postman]
    end

    subgraph API-GW[API Gateway]
        B1[Load service config]
        B2[Fetch & Merge OpenAPI JSON]
        B3[Auto-generate routes]
        B4[Forward request to service]
    end

    subgraph SRV[Microservices]
        C1[User Service]
        C2[Post Service]
        C3[Payment Service]
    end

    A -->|GET /users/123| API-GW
    API-GW -->|Forward /users/123| C1
    C1 -->|JSON response| API-GW
    API-GW -->|Return JSON| A

4️⃣ Tóm tắt
Thành phần	Vai trò
API Gateway	Entrypoint duy nhất, route tự động dựa trên OpenAPI JSON
OpenAPI JSON	Hợp đồng giữa gateway & service, mô tả endpoint / schema
Microservices	Xử lý nghiệp vụ riêng, deploy & scale độc lập
Client	Gọi API qua gateway mà không cần biết chi tiết backend