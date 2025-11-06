API Gateway
1️⃣ Giới thiệu

API Gateway là cổng trung gian duy nhất cho tất cả client (Frontend, Mobile, Postman) truy cập vào hệ thống backend.
Nó forward request tới các microservice dựa trên OpenAPI JSON của từng service.

Hệ thống backend tổ chức dạng monorepo:

backend/
├── api-gateway/        # API Gateway (entrypoint)
├── user-service/       # Quản lý người dùng
├── post-service/       # Quản lý bài viết
├── payment-service/    # Thanh toán
└── ...                 # Các service khác

2️⃣ Quy trình chạy hệ thống
Bước 1: Cài đặt dependencies
# Tại root repo
pnpm install

Bước 2: Chạy toàn bộ hệ thống
pnpm run dev


API Gateway sẽ start trên port (ví dụ 3000)

Mỗi microservice start trên port riêng (user-service: 3001, post-service: 3002...)

Bước 3: Kiểm tra OpenAPI JSON

Gateway tự động nạp file openapi.json từ từng service và merge thành OpenAPI tổng hợp.

Endpoint mới từ service nào cũng tự động được sinh route.

Không cần chỉnh code gateway thủ công.

3️⃣ Mô tả luồng hoạt động (OpenAPI JSON Flow)

Client gọi API:

GET /users/123


Gateway:

Kiểm tra route /users/{id} từ OpenAPI tổng hợp

Forward request tới user-service

Nhận response → trả về client

Lợi ích:

Frontend chỉ cần gọi gateway

Microservice deploy & scale độc lập

OpenAPI JSON đảm bảo type safety và auto-docs

4️⃣ Sơ đồ minh họa
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

5️⃣ Quy trình phát triển & role team
Team roles
Team	Quyền hạn trên branch dev
Dev Team	Tạo branch feature, push PR, merge PR sau review
QA Team	Chỉ review PR, test trên dev, không push
Release Team	Merge release, deploy production, có thể push trực tiếp
Branch workflow
feature/<tinh-nang-moi> → PR → review → merge vào dev


Không push trực tiếp vào dev trừ khi được phép (branch protection rule)

CI/CD check sẽ chạy trước khi merge

6️⃣ Thêm service mới

Tạo microservice mới → định nghĩa openapi.json.

Thêm service vào config gateway.

Gateway tự merge spec → route mới sinh tự động.

7️⃣ Lợi ích của kiến trúc

Một entrypoint duy nhất cho client

Dễ mở rộng: thêm service mới không sửa gateway code

Type-safe & auto-docs nhờ OpenAPI JSON

Team có role rõ ràng, dễ quản lý branch/merge