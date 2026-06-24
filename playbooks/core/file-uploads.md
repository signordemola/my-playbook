## 22. File Uploads

> **Sources:** [OWASP File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html),
> [Vercel Blob docs](https://vercel.com/docs/storage/vercel-blob),
> [UploadThing docs](https://docs.uploadthing.com)

---

### Architecture: Never Stream Through Your Server

Serverless functions have payload limits (4.5MB on Vercel) and timeout risks.
Always upload directly from the client to storage using presigned/signed URLs.

```
1. Client requests upload URL  →  Server Action (validates auth + file metadata)
2. Server generates presigned URL  →  returns to client
3. Client uploads directly to storage (S3 / Vercel Blob / UploadThing)
4. Client notifies server  →  save file metadata (key, size, type) to DB
```

---

### Choosing Your Storage Provider

| Solution | Best For | Pricing | Setup Complexity |
| -------- | -------- | ------- | ---------------- |
| **UploadThing** | Next.js-first teams, fast setup | Free tier (2GB), paid after | Low — handles auth, validation, cleanup |
| **Vercel Blob** | Vercel-deployed apps | Free tier (256MB), pay-as-you-go | Low — deep Vercel integration |
| **AWS S3** | Full control, high volume | Cheapest at scale | High — IAM, CORS, bucket policies |

**For most booking systems:** Start with UploadThing or Vercel Blob. Move to S3 only if you need cost optimization at volume (> 50GB/month).

---

### Implementation: S3 Presigned URLs

#### Server Action: Generate URL

```typescript
// actions/upload.ts
"use server"
import { S3Client, PutObjectCommand } from "@aws-sdk/client-s3"
import { getSignedUrl } from "@aws-sdk/s3-request-presigner"
import { nanoid } from "nanoid"
import { requireSession } from "@/lib/dal"

const s3 = new S3Client({ region: process.env.AWS_REGION })

const ALLOWED_TYPES = ["image/jpeg", "image/png", "image/webp", "application/pdf"]
const MAX_SIZE = 10 * 1024 * 1024  // 10MB

export async function getUploadUrl(formData: FormData) {
  const session = await requireSession()

  const fileName = formData.get("fileName") as string
  const fileType = formData.get("fileType") as string
  const fileSize = Number(formData.get("fileSize"))

  // Server-side validation — never trust the client
  if (!ALLOWED_TYPES.includes(fileType)) {
    return { success: false, errors: { file: ["File type not allowed"] } }
  }
  if (fileSize > MAX_SIZE) {
    return { success: false, errors: { file: ["File too large (max 10MB)"] } }
  }

  // Generate a unique key — never use the original filename
  const ext = fileName.split(".").pop()
  const key = `uploads/${session.user.id}/${nanoid()}.${ext}`

  const command = new PutObjectCommand({
    Bucket: process.env.S3_BUCKET!,
    Key: key,
    ContentType: fileType,
    ContentLength: fileSize,  // Enforce exact size
  })

  const url = await getSignedUrl(s3, command, { expiresIn: 300 }) // 5 min TTL

  return { success: true, data: { url, key } }
}
```

#### Client: Direct Upload

```typescript
// components/upload-button.tsx
"use client"

export async function uploadFile(file: File) {
  // 1. Get presigned URL from server
  const formData = new FormData()
  formData.set("fileName", file.name)
  formData.set("fileType", file.type)
  formData.set("fileSize", String(file.size))
  const result = await getUploadUrl(formData)

  if (!result.success) throw new Error("Upload validation failed")

  // 2. Upload directly to S3 — bypasses the Next.js server entirely
  await fetch(result.data.url, {
    method: "PUT",
    body: file,
    headers: { "Content-Type": file.type },
  })

  // 3. Save metadata to DB
  await saveFileMetadata({
    key: result.data.key,
    originalName: file.name,
    size: file.size,
    type: file.type,
  })
}
```

---

### Implementation: Vercel Blob (Simpler)

```typescript
// actions/upload.ts
"use server"
import { put } from "@vercel/blob"
import { requireSession } from "@/lib/dal"

export async function uploadToBlob(formData: FormData) {
  const session = await requireSession()
  const file = formData.get("file") as File

  if (!file || file.size > 10 * 1024 * 1024) {
    return { success: false, errors: { file: ["Invalid file"] } }
  }

  const blob = await put(`uploads/${session.user.id}/${file.name}`, file, {
    access: "public",  // or "private" for sensitive docs
  })

  return { success: true, data: { url: blob.url } }
}
```

---

### Security Checklist

| Rule | Implementation |
| ---- | -------------- |
| **Never expose storage credentials client-side** | Presigned URLs generated server-side only |
| **Validate file type server-side** | Check MIME type AND magic bytes — don't trust `Content-Type` header |
| **Limit file size** | Set `ContentLength` on presigned URL + validate in Server Action |
| **Sanitise filenames** | Never store the original filename — generate `nanoid()` keys |
| **Set upload TTL** | `expiresIn: 300` (5 minutes) — prevents URL reuse |
| **Enforce auth before upload** | `requireSession()` before generating any URL |
| **Rate limit upload endpoint** | 5 uploads / 60 sec per user — prevents abuse |
| **Clean up abandoned uploads** | S3 Lifecycle Policy → auto-delete incomplete multipart after 24h |
| **Strip metadata from images** | Remove EXIF data (GPS, device info) for privacy |
| **Isolate storage** | Separate bucket/container — not in your app's web root |
| **Least-privilege credentials** | Upload-only IAM role — can't list or delete other files |

---

### File Validation: Two Layers

```typescript
// Client-side — instant UX feedback
const validateFile = (file: File): string | null => {
  const ALLOWED = ["image/jpeg", "image/png", "image/webp", "application/pdf"]
  const MAX_MB = 10

  if (!ALLOWED.includes(file.type)) return "File type not allowed"
  if (file.size > MAX_MB * 1024 * 1024) return `File too large (max ${MAX_MB}MB)`
  return null
}

// Server-side — security (NEVER skip this even if client validates)
// See the Server Action above — re-validates type + size before generating URL
```

**Why both?** The client validation gives instant feedback. But the server validation is the security layer — a malicious client can bypass any client-side check.

---

### Large Files: Multipart Upload (> 100MB)

For before/after cleaning photos or large documents:

1. **Initiate:** Server Action creates multipart upload, returns `uploadId`
2. **Chunk:** Client slices file into 5–10MB parts using `File.slice()`
3. **Upload:** Each chunk gets its own presigned URL, uploaded in parallel
4. **Complete:** Server Action assembles the file on S3

> Only implement multipart if you genuinely need files > 100MB.
> For typical booking systems (photos, PDFs), 10MB limit with standard upload is sufficient.

---

### Booking-Specific Use Cases

| Use Case | File Types | Max Size | Storage |
| -------- | ---------- | -------- | ------- |
| **Before/after photos** | JPEG, PNG, WebP | 10MB | Public (portfolio) |
| **Client documents** | PDF | 5MB | Private (signed URLs) |
| **Provider credentials** | PDF, JPEG | 5MB | Private |
| **Profile photos** | JPEG, PNG, WebP | 2MB | Public |
| **Chat attachments** | JPEG, PNG, PDF | 5MB | Private |

---

### Database Schema for File Metadata

```prisma
model FileUpload {
  id           String   @id @default(cuid())
  key          String   @unique  // Storage path (S3 key or Blob URL)
  originalName String            // For display only — never used as storage path
  size         Int               // Bytes
  mimeType     String
  uploadedBy   String            // User or client ID
  entity       String?           // "visit", "client", "portfolio"
  entityId     String?           // Related record ID
  status       String   @default("ACTIVE")  // ACTIVE, DELETED
  createdAt    DateTime @default(now())

  @@index([entity, entityId])
  @@index([uploadedBy])
}
```
