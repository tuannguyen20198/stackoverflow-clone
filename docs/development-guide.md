📂 Cấu trúc folder/ghi chú role trong repo

# Dev Team

## Thành viên
- Tuan
- Nguyên
- Tú
- Duy

## Quyền hạn
- Push code lên feature branch: ✅ Có
- Merge PR vào `dev`: ✅ Có (cần review từ team lead)
- Push trực tiếp vào `dev`: ⚠️ Chỉ team lead mới được phép
- Tạo branch mới: ✅ Có

## Quy trình làm việc
1. Checkout branch feature:
```bash
git checkout -b feature/tinh-nang-moi
Push branch feature lên remote:

bash
Copy code
git push origin feature/tinh-nang-moi
Tạo PR → team lead review → merge vào dev.

yaml
Copy code

---

### 📄 Gợi ý file `qa-team.md`

```markdown
# QA Team

## Thành viên
- Tuan
- Nguyên
- Tú
- Duy

## Quyền hạn
- Push code: ❌ Không
- Merge PR: ❌ Không
- Review PR: ✅ Có
- Test code trên nhánh `dev`: ✅ Có
⚡ Tips đặt tên folder/file
Tên folder: roles/ hoặc team/

Tên file: <team-name>.md → ví dụ dev-team.md, qa-team.md, release-team.md

Trong file mô tả:

Thành viên

Quyền hạn trên branch quan trọng (dev, main)

Quy trình làm việc (PR workflow, CI/CD check, code review)