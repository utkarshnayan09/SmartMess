# SmartMess Design System: Smart Campus Mess & Flow Platform

> **Project ID:** `projects/9633191360936766641`  
> **Target Device:** Mobile-first responsive  
> **Aesthetic North Star:** Responsive collegiate food-tech SaaS balancing student real-time utility with admin kitchen throughput clarity.

---

## 1. Brand & Aesthetic Direction

The design system establishes a responsive, mobile-first food-tech SaaS aesthetic tailored to collegiate living. It balances dynamic, real-time utility for students rushing between classes with administrative clarity for dining hall operators managing throughput and meal schedules.

- **Atmosphere:** Efficient, breezy, clean, and reassuringly immediate.
- **Audience:** Tech-forward university students, mess monitors, kitchen operators, and hostel administration.
- **Design Metaphor:** An intelligent live departure board crossbred with a modern micro-cafeteria ordering experience. Surfaces are soft white resting on gentle slate backdrops, accented by fresh botanical teals and instant live status signifiers.

---

## 2. Color Palette & Hierarchy

| Role | Color Hex | Usage |
| :--- | :--- | :--- |
| **Primary** | `#00685F` (`#0D9488`) | Deep oceanic teal driving primary interactions, active tab indicators, verified credential tags |
| **Primary Container** | `#008378` | Highlighted cards, prominent CTA backgrounds |
| **Secondary** | `#006C4A` (`#059669`) | Fresh emerald accentuating meal check-in clearances, successful transactions, nutritious selections |
| **Tertiary** | `#825100` (`#F59E0B`) | Warm amber handling middle-tier wait times and advisory queue notifications |
| **Surface** | `#FAF8FF` | Pristine canvas foundation |
| **Surface Container** | `#EAEDFF` | Standard card and section backgrounds |
| **Surface Container High** | `#E2E7FF` | Elevated chips, badge containers |
| **On-Surface** | `#131B2E` | Deep slate/charcoal text anchoring headlines and metrics |
| **Error / Alert** | `#BA1A1A` | Critical bottlenecks, warnings |

### Live Crowd-Status Engine

| Status | Text Color | Background | Border | Label |
| :--- | :--- | :--- | :--- | :--- |
| **Low Density** | `#059669` | `#ECFDF5` | `#A7F3D0` | Flowing (< 5 min wait) |
| **Moderate** | `#D97706` | `#FFFBEB` | `#FDE68A` | Building (5–15 min wait) |
| **Peak Crowd** | `#DC2626` | `#FEF2F2` | `#FECACA` | Bottleneck (> 15 min wait) |

---

## 3. Typography: Plus Jakarta Sans

- **Numbers & Metrics:** Use tabular lining figures (`font-variant-numeric: tabular-nums`) to prevent jittering when counters tick down.
- **Hierarchy:** High-contrast weights (700/800 for milestones and queue tiers; 400 for dietary descriptions).

| Style | Size | Weight | Line Height | Letter Spacing |
| :--- | :--- | :--- | :--- | :--- |
| `display-lg` | 40px | 800 | 48px | -0.03em |
| `headline-xl` | 32px | 700 | 40px | -0.025em |
| `headline-lg` | 24px | 700 | 32px | -0.02em |
| `title-md` | 18px | 600 | 24px | -0.01em |
| `body-lg` | 16px | 400 | 24px | 0em |
| `body-md` | 14px | 400 | 20px | 0em |
| `label-lg` | 14px | 600 | 18px | 0.01em |
| `label-md` | 12px | 600 | 16px | 0.02em |
| `label-sm` | 10px | 700 | 14px | 0.04em |

---

## 4. Components & Elevation

- **Level 0 (Canvas):** Flat base `#FAF8FF`.
- **Level 1 (Cards, Menu Rows):** White `#FFFFFF`, border `1px solid #E2E8F0`, shadow `0 1px 3px rgba(15, 23, 42, 0.04)`.
- **Level 2 (Floating Bar & Popovers):** Elevated `#FFFFFF`, shadow `0 10px 15px -3px rgba(15, 23, 42, 0.06)`.
- **Level 3 (Action Drawers, Live QR Modal):** `#FFFFFF` with backdrop blur, shadow `0 20px 25px -5px rgba(15, 23, 42, 0.1)`.
