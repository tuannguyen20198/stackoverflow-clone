## ⚙️ Quy trình hoạt động của hệ thống

Hệ thống được thiết kế theo kiến trúc **Fullstack Monorepo** gồm:

- **Frontend (Next.js)** — Ứng dụng giao diện người dùng, chạy ở thư mục `apps/web`
- **Backend (NestJS + Nx)** — Hệ thống API trung tâm đặt tại `apps/api` (hoặc `backend/api-gateway`)
- **API Gateway** — Thành phần điều phối toàn bộ request, đồng thời sinh tài liệu OpenAPI tự động
- **OpenAPI** — Chuẩn hóa tài liệu API, giúp frontend và backend giao tiếp đồng bộ qua spec chung (`swagger.json`)

---

### 🔄 Luồng hoạt động tổng quan

1. **Người dùng truy cập Frontend (Next.js)**  
   → Gửi yêu cầu (HTTP request / GraphQL / Fetch API) đến endpoint backend thông qua **API Gateway**  
   → Ví dụ:  
   ```bash
   GET https://api.example.com/users
API Gateway (NestJS) tiếp nhận request

Xác thực token / session (middleware)

Ghi log request, áp dụng rate limit

Định tuyến request tới đúng module hoặc microservice phía sau (ví dụ: user-service, order-service)

Các module nghiệp vụ (NestJS Modules) xử lý dữ liệu

Gọi tới database hoặc external service

Trả về dữ liệu JSON hoặc lỗi có chuẩn hóa (response DTO)

API Gateway trả kết quả về Frontend

Toàn bộ response đều tuân theo định dạng chung ({ status, data, message })

Nếu có lỗi, thông tin chi tiết được chuẩn hóa (HTTP Code + message)

Frontend (Next.js) hiển thị kết quả cho người dùng

Dựa trên API spec (OpenAPI) → sinh sẵn type an toàn (@api/types)

Giảm lỗi khi gọi API nhờ có schema đồng bộ giữa FE & BE

📘 OpenAPI Integration
Hệ thống tự động sinh tài liệu API (Swagger) từ backend NestJS.

Cấu hình trong apps/api/src/main.ts (hoặc backend/api-gateway/src/main.ts):

ts
Copy code
import { SwaggerModule, DocumentBuilder } from '@nestjs/swagger';

const config = new DocumentBuilder()
  .setTitle('API Gateway')
  .setDescription('OpenAPI documentation for all backend services')
  .setVersion('1.0')
  .addBearerAuth()
  .build();

const document = SwaggerModule.createDocument(app, config);
SwaggerModule.setup('docs', app, document);
Khi chạy backend:

bash
Copy code
http://localhost:3001/docs
→ Xem tài liệu OpenAPI trực tiếp bằng Swagger UI.

🧩 Kết nối Frontend với OpenAPI
Frontend (Next.js) sử dụng OpenAPI Generator để sinh type-safe API client.

Ví dụ trong apps/web/package.json:

json
Copy code
{
  "scripts": {
    "generate:api": "openapi-generator-cli generate -i http://localhost:3001/docs-json -g typescript-fetch -o src/api"
  }
}
Sau khi chạy:

bash
Copy code
pnpm run generate:api
→ Sinh ra các file như src/api/base.ts, src/api/apis/*.ts, có type định nghĩa sẵn.
Khi gọi API:

ts
Copy code
import { UsersApi } from '@/api';

const users = await new UsersApi().getUsers();
Từ đó:

FE luôn đồng bộ 100% với backend

Không cần tự gõ URL hoặc DTO thủ công

Tự động báo lỗi khi backend đổi schema

🧠 Tóm tắt hoạt động
Thành phần	Vai trò	Công nghệ	Ghi chú
apps/web	Giao diện người dùng	Next.js (React)	Gọi API qua OpenAPI client
apps/api / backend/api-gateway	Cổng giao tiếp chính của hệ thống	NestJS + Nx	Tích hợp Swagger, OpenAPI, JWT
OpenAPI	Chuẩn hóa API	SwaggerModule (NestJS)	Sinh tự động spec JSON
Turborepo	Quản lý monorepo	turbo.json	Dev song song FE & BE
Nx	Quản lý build backend	nx.json	Build, serve, test backend
