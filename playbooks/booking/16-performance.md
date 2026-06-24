## 16. Performance Budgets

> **Source:** [web.dev — Core Web Vitals](https://web.dev/articles/vitals)
> Google uses the **75th percentile** of real-user data (CrUX) for ranking.
> Always prioritise **field data** (CrUX) over lab/Lighthouse scores.

---

### Core Web Vitals 2026 Thresholds

| Metric                              | Measures         | Good    | Needs Work | Poor    |
| ----------------------------------- | ---------------- | ------- | ---------- | ------- |
| **LCP** (Largest Contentful Paint)  | Loading speed    | ≤ 2.5s  | ≤ 4.0s     | > 4.0s  |
| **INP** (Interaction to Next Paint) | Responsiveness   | ≤ 200ms | ≤ 500ms    | > 500ms |
| **CLS** (Cumulative Layout Shift)   | Visual stability | ≤ 0.1   | ≤ 0.25     | > 0.25  |

> **INP replaced FID in March 2024.** INP measures ALL interactions (not just the first),
> making it a much stricter test. If you pass INP, you're genuinely responsive.

---

### Resource Budgets

| Resource                | Budget                        | Why                                                |
| ----------------------- | ----------------------------- | -------------------------------------------------- |
| **Total JS**            | < 170 KB compressed           | #1 cause of poor INP — main thread blocking        |
| **Total Images**        | < 1000 KB per page            | Use WebP/AVIF + `next/image` for auto-optimization |
| **Fonts**               | ≤ 2 font families             | Use `next/font` for zero-CLS font loading          |
| **Third-party scripts** | Defer everything non-critical | Chat widgets, analytics → load after LCP           |

---

### Next.js 16 Performance Architecture

#### Partial Prerendering (PPR)
The single biggest performance feature in Next.js 16. Combines static and dynamic rendering in one route:

1. **Build time:** Next.js generates a static "shell" (header, nav, layout) as HTML
2. **Request time:** Dynamic content wrapped in `<Suspense>` streams in parallel
3. **Result:** Instant TTFB + progressive loading of personalised content

```typescript
// Dashboard page using PPR
export default async function DashboardPage() {
  return (
    <div>
      {/* Static shell — served instantly from edge */}
      <h1>Dashboard</h1>
      <nav><DashboardNav /></nav>

      {/* Dynamic — streams in after initial paint */}
      <Suspense fallback={<KPICardsSkeleton />}>
        <KPICards />  {/* Server Component that reads cookies + queries DB */}
      </Suspense>

      <Suspense fallback={<ScheduleTableSkeleton />}>
        <TodaySchedule />
      </Suspense>
    </div>
  )
}
```

#### Turbopack (Default Bundler)
- 2–5x faster production builds vs webpack
- Up to 10x faster Fast Refresh in development
- File-system caching eliminates redundant work across builds
- No configuration needed — it's the default in Next.js 16

#### `use cache` Directive
Replaces the legacy `unstable_cache` and implicit caching. Explicit, fine-grained control:

```typescript
async function getServicePricing() {
  "use cache"
  // This result is cached until manually revalidated
  return prisma.pricingTier.findMany({ include: { serviceType: true } })
}
```

---

### Image Optimization (`next/image`)

#### Configuration
```typescript
// next.config.ts
const nextConfig = {
  images: {
    formats: ['image/avif', 'image/webp'],  // Prefer AVIF (40% smaller than WebP)
  },
}
```

#### Rules

| Scenario | Props | Why |
| -------- | ----- | --- |
| **Hero / LCP image** | `priority` | Preloads the image — do NOT lazy load |
| **Below the fold** | `loading="lazy"` (default) | Defers download until near viewport |
| **All images** | `width` + `height` or static import | Prevents CLS — required |
| **Responsive** | `sizes="(max-width: 768px) 100vw, 50vw"` | Avoids downloading oversized images |

```tsx
// Hero image — preloaded for LCP
<Image
  src="/hero-clean-home.jpg"
  alt="Sparkling clean living room"
  width={1200}
  height={600}
  priority          // ← Preloads — critical for LCP
  sizes="100vw"
/>

// Team member photo — lazy loaded
<Image
  src={cleaner.photoUrl}
  alt={`${cleaner.name}, Greenleaf cleaner`}
  width={80}
  height={80}
  className="rounded-full"
  // loading="lazy" is the default — no need to specify
/>
```

---

### Font Loading (`next/font`)

Zero-CLS font loading with automatic self-hosting:

```typescript
// app/layout.tsx
import { Inter } from "next/font/google"

const inter = Inter({
  subsets: ["latin"],
  display: "swap",       // Show fallback immediately, swap when loaded
  variable: "--font-inter",
})

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className={inter.variable}>
      <body>{children}</body>
    </html>
  )
}
```

**What `next/font` does automatically:**
- Downloads font files at build time → self-hosts them (no Google Fonts request at runtime)
- Applies `size-adjust` to match fallback font metrics → virtually zero CLS
- Generates CSS `@font-face` declarations with optimal settings

**Rules:**
- Use **variable fonts** when available (one file covers all weights)
- Limit to **≤ 2 font families** per site
- Use `display: "swap"` — text is visible immediately with fallback font
- Never load fonts via `<link>` tags to Google Fonts — use `next/font` instead

---

### Prefetching & Navigation

Next.js automatically prefetches linked routes when `<Link>` components enter the viewport:

```tsx
import Link from "next/link"

// ✅ Automatically prefetched when visible in viewport
<Link href="/book">Book a Clean</Link>

// ✅ Disable prefetch for low-priority links (e.g., footer links)
<Link href="/privacy" prefetch={false}>Privacy Policy</Link>
```

---

### Bundle Size Analysis

```bash
# Turbopack-based analysis
npx next experimental-analyze

# Or use the classic bundle analyzer
pnpm add -D @next/bundle-analyzer
```

**What to look for:**
- Client components importing server-only libraries (e.g., Prisma leaking to client bundle)
- Full library imports instead of modular (`import _ from "lodash"` vs `import debounce from "lodash/debounce"`)
- Heavy client-side chart libraries — use `next/dynamic` to lazy load them

```typescript
// Lazy load a heavy chart component — only sent to client when rendered
import dynamic from "next/dynamic"

const RevenueChart = dynamic(() => import("@/components/dashboard/revenue-chart"), {
  loading: () => <ChartSkeleton />,
  ssr: false,  // Don't server-render the chart — it needs browser APIs
})
```

---

### Booking-Specific Performance Rules

1. **Hero + CTA load first.** The booking button must be in the initial viewport and interactive within 2.5s.
2. **Reserve space for dynamic UI.** Always set `width` + `height` on images and time slot containers to prevent CLS.
3. **Calendar widgets: lazy load.** Don't ship the date picker JS until the user interacts with the date field. Use `next/dynamic` or a `<Suspense>` boundary.
4. **Skeleton loading everywhere.** Every route must have a `loading.tsx` with content-aware skeletons, not generic spinners.
5. **Instant quote must feel instant.** < 200ms perceived response time. Use Redis cache + optimistic UI (show calculating state, then snap to result).

---

### CI/CD Performance Enforcement

```typescript
// next.config.ts — fail build on bundle size regression
const nextConfig = {
  experimental: {
    outputFileTracingIncludes: { "/**": ["./node_modules/**"] },
  },
}
```

**Manual checks per PR:**
- Run Lighthouse CI → compare against budgets
- Block merges that regress LCP or INP past thresholds
- Monitor `next build` output for "First Load JS" per route — flag any route > 170KB

---

### Performance Testing Matrix

| Test | Tool | Frequency | Pass Criteria |
| ---- | ---- | --------- | ------------- |
| **Build size** | `next build` output | Every PR | No route > 170KB First Load JS |
| **Lighthouse** | Lighthouse CI | Every PR | Score ≥ 90 on public pages |
| **CWV (lab)** | Chrome DevTools Performance tab | Weekly | LCP ≤ 2.5s, INP ≤ 200ms, CLS ≤ 0.1 |
| **CWV (field)** | CrUX / PageSpeed Insights | Monthly | 75th percentile in "Good" range |
| **Bundle analysis** | `next experimental-analyze` | Monthly | No unexpected library in client bundle |
