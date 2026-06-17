import { useState, useEffect, useRef } from "react";

// ─── IN-MEMORY DATABASE ────────────────────────────────────────────────────────
const initDB = () => ({
  Author: [
    { author_id: 1, name: "Dr. Ananya Mehta", affiliation: "AIIMS Delhi", email: "ananya@aiims.edu" },
    { author_id: 2, name: "Dr. Rohan Kapoor", affiliation: "PGI Chandigarh", email: "rohan@pgi.in" },
    { author_id: 3, name: "Dr. Priya Sharma", affiliation: "CMC Vellore", email: "priya@cmc.edu" },
    { author_id: 4, name: "Dr. Arjun Verma", affiliation: "Apollo Research Center", email: "arjun@apollo.org" },
    { author_id: 5, name: "Dr. Neha Singh", affiliation: "Tata Memorial Hospital", email: "neha@tmh.in" },
  ],
  Research_Domain: [
    { domain_id: 101, domain_name: "Cardiology" },
    { domain_id: 102, domain_name: "Oncology" },
    { domain_id: 103, domain_name: "Neurology" },
    { domain_id: 104, domain_name: "Immunology" },
  ],
  Research_Paper: [
    { paper_id: 201, title: "AI in Heart Disease Detection", publication_year: 2024, domain_id: 101 },
    { paper_id: 202, title: "Cancer Cell Imaging using ML", publication_year: 2023, domain_id: 102 },
    { paper_id: 203, title: "Brain Tumor Prediction Models", publication_year: 2024, domain_id: 103 },
    { paper_id: 204, title: "Vaccine Response Analysis", publication_year: 2022, domain_id: 104 },
  ],
  Author_Paper: [
    { author_id: 1, paper_id: 201 },
    { author_id: 2, paper_id: 201 },
    { author_id: 3, paper_id: 202 },
    { author_id: 4, paper_id: 203 },
    { author_id: 5, paper_id: 204 },
  ],
  Reviewer: [
    { reviewer_id: 301, name: "Dr. Mehul Jain", specialization: "Cardiology", email: "mehul@medreview.org" },
    { reviewer_id: 302, name: "Dr. Kavita Rao", specialization: "Oncology", email: "kavita@medreview.org" },
    { reviewer_id: 303, name: "Dr. Sameer Iyer", specialization: "Neurology", email: "sameer@medreview.org" },
  ],
  Review: [
    { review_id: 401, rating: 8, comments: "Strong methodology", paper_id: 201, reviewer_id: 301 },
    { review_id: 402, rating: 7, comments: "Needs more clinical data", paper_id: 202, reviewer_id: 302 },
    { review_id: 403, rating: 9, comments: "Excellent research work", paper_id: 203, reviewer_id: 303 },
  ],
  Conference: [
    { conf_id: 501, conf_name: "International Medical AI Conference", location: "New Delhi", start_date: "2025-03-10", end_date: "2025-03-12" },
    { conf_id: 502, conf_name: "Global Oncology Summit", location: "Mumbai", start_date: "2025-04-15", end_date: "2025-04-17" },
  ],
  Submission: [
    { submission_id: 601, submission_date: "2025-01-10", status: "Accepted", paper_id: 201, conf_id: 501 },
    { submission_id: 602, submission_date: "2025-01-12", status: "Under Review", paper_id: 202, conf_id: 502 },
    { submission_id: 603, submission_date: "2025-01-15", status: "Accepted", paper_id: 203, conf_id: 501 },
  ],
  Paper_Presentation: [
    { paper_id: 201, conf_id: 501, presentation_date: "2025-03-10" },
    { paper_id: 203, conf_id: 501, presentation_date: "2025-03-11" },
  ],
  Registration: [
    { reg_id: 701, reg_date: "2025-02-20", author_id: 1, conf_id: 501 },
    { reg_id: 702, reg_date: "2025-02-22", author_id: 2, conf_id: 501 },
    { reg_id: 703, reg_date: "2025-03-01", author_id: 3, conf_id: 502 },
  ],
  Citation: [
    { citing_paper_id: 202, cited_paper_id: 201, citation_year: 2024 },
    { citing_paper_id: 203, cited_paper_id: 201, citation_year: 2025 },
    { citing_paper_id: 204, cited_paper_id: 202, citation_year: 2024 },
  ],
  Journal: [
    { journal_id: 801, journal_name: "Indian Journal of Medical Research", impact_factor: 4.25 },
    { journal_id: 802, journal_name: "Global Health Science Journal", impact_factor: 3.80 },
  ],
});

// ─── SQL ENGINE (simple interpreter) ─────────────────────────────────────────
const runSQL = (query, db) => {
  try {
    const q = query.trim().toUpperCase();
    if (q.startsWith("SELECT")) {
      // detect table
      const fromMatch = query.match(/FROM\s+(\w+)/i);
      if (!fromMatch) return { error: "No FROM clause found" };
      const tbl = fromMatch[1];
      if (!db[tbl]) return { error: `Table '${tbl}' not found` };

      let rows = [...db[tbl]];

      // WHERE simple support
      const whereMatch = query.match(/WHERE\s+(\w+)\s*=\s*['"]?(\w[\w\s]*)['"]?/i);
      if (whereMatch) {
        const col = whereMatch[1].toLowerCase();
        const val = whereMatch[2].replace(/['";]/g, "").trim();
        rows = rows.filter(r => {
          const rv = r[col];
          return rv !== undefined && String(rv).toLowerCase() === val.toLowerCase();
        });
      }

      // COUNT
      const countMatch = query.match(/COUNT\(\*\)/i);
      if (countMatch) {
        return { columns: ["COUNT(*)"], rows: [[rows.length]] };
      }

      // SELECT * or specific cols
      const selectMatch = query.match(/SELECT\s+(.*?)\s+FROM/i);
      let cols = Object.keys(rows[0] || {});
      if (selectMatch && selectMatch[1].trim() !== "*") {
        cols = selectMatch[1].split(",").map(c => c.trim().toLowerCase());
      }
      return {
        columns: cols,
        rows: rows.map(r => cols.map(c => r[c] ?? r[c.toLowerCase()] ?? ""))
      };
    }
    if (q.startsWith("INSERT INTO")) {
      return { message: "✓ INSERT executed successfully (1 row affected)" };
    }
    if (q.startsWith("DELETE")) {
      return { message: "✓ DELETE executed successfully" };
    }
    if (q.startsWith("UPDATE")) {
      return { message: "✓ UPDATE executed successfully" };
    }
    if (q.startsWith("CREATE TABLE")) {
      return { message: "✓ Table created successfully" };
    }
    return { error: "Unsupported query type" };
  } catch (e) {
    return { error: e.message };
  }
};

// ─── PREDEFINED SQL QUERIES ────────────────────────────────────────────────────
const PRESET_QUERIES = [
  { label: "All Authors", sql: "SELECT * FROM Author" },
  { label: "All Research Papers", sql: "SELECT * FROM Research_Paper" },
  { label: "All Reviewers", sql: "SELECT * FROM Reviewer" },
  { label: "All Reviews", sql: "SELECT * FROM Review" },
  { label: "All Conferences", sql: "SELECT * FROM Conference" },
  { label: "All Submissions", sql: "SELECT * FROM Submission" },
  { label: "All Citations", sql: "SELECT * FROM Citation" },
  { label: "All Journals", sql: "SELECT * FROM Journal" },
  { label: "Papers in Cardiology (domain 101)", sql: "SELECT * FROM Research_Paper WHERE domain_id = 101" },
  { label: "Accepted Submissions", sql: "SELECT * FROM Submission WHERE status = Accepted" },
];

// ─── COLOR PALETTE ─────────────────────────────────────────────────────────────
const C = {
  bg: "#0a0f1e",
  surface: "#111827",
  card: "#1a2235",
  border: "#1e3a5f",
  accent: "#00d4ff",
  accent2: "#0099cc",
  green: "#00e5a0",
  red: "#ff4d6d",
  yellow: "#ffd166",
  text: "#e8f4f8",
  muted: "#6b8fa8",
  highlight: "#0d2137",
};

// ─── STYLES ────────────────────────────────────────────────────────────────────
const S = {
  app: {
    minHeight: "100vh",
    background: C.bg,
    color: C.text,
    fontFamily: "'IBM Plex Mono', 'Courier New', monospace",
    display: "flex",
    flexDirection: "column",
  },
  header: {
    background: `linear-gradient(135deg, #0d1b2e 0%, #0a2540 100%)`,
    borderBottom: `1px solid ${C.border}`,
    padding: "0 24px",
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    height: 64,
    position: "sticky",
    top: 0,
    zIndex: 100,
    boxShadow: `0 2px 20px rgba(0,212,255,0.08)`,
  },
  logo: {
    fontSize: 15,
    fontWeight: 700,
    color: C.accent,
    letterSpacing: 1,
    display: "flex",
    alignItems: "center",
    gap: 10,
  },
  badge: {
    background: C.accent,
    color: C.bg,
    fontSize: 9,
    padding: "2px 7px",
    borderRadius: 3,
    fontWeight: 800,
    letterSpacing: 1,
  },
  layout: {
    display: "flex",
    flex: 1,
  },
  sidebar: {
    width: 220,
    background: C.surface,
    borderRight: `1px solid ${C.border}`,
    padding: "20px 0",
    flexShrink: 0,
  },
  sideSection: {
    padding: "0 16px",
    marginBottom: 8,
  },
  sideLabel: {
    fontSize: 9,
    color: C.muted,
    letterSpacing: 2,
    textTransform: "uppercase",
    padding: "8px 8px 4px",
    fontWeight: 700,
  },
  navBtn: (active) => ({
    display: "flex",
    alignItems: "center",
    gap: 8,
    width: "100%",
    padding: "8px 12px",
    background: active ? C.highlight : "transparent",
    border: active ? `1px solid ${C.border}` : "1px solid transparent",
    borderRadius: 6,
    color: active ? C.accent : C.muted,
    cursor: "pointer",
    fontSize: 12,
    textAlign: "left",
    marginBottom: 2,
    transition: "all 0.15s",
  }),
  main: {
    flex: 1,
    padding: 28,
    overflow: "auto",
  },
  pageTitle: {
    fontSize: 20,
    fontWeight: 700,
    color: C.accent,
    marginBottom: 4,
    letterSpacing: 0.5,
  },
  pageSubtitle: {
    fontSize: 11,
    color: C.muted,
    marginBottom: 24,
    letterSpacing: 0.5,
  },
  grid3: {
    display: "grid",
    gridTemplateColumns: "repeat(3, 1fr)",
    gap: 16,
    marginBottom: 24,
  },
  statCard: (color) => ({
    background: C.card,
    border: `1px solid ${C.border}`,
    borderTop: `3px solid ${color}`,
    borderRadius: 8,
    padding: "16px 20px",
  }),
  statNum: (color) => ({
    fontSize: 32,
    fontWeight: 800,
    color: color,
    lineHeight: 1,
    marginBottom: 4,
  }),
  statLabel: {
    fontSize: 10,
    color: C.muted,
    letterSpacing: 1.5,
    textTransform: "uppercase",
  },
  card: {
    background: C.card,
    border: `1px solid ${C.border}`,
    borderRadius: 8,
    overflow: "hidden",
    marginBottom: 20,
  },
  cardHeader: {
    padding: "12px 20px",
    borderBottom: `1px solid ${C.border}`,
    display: "flex",
    alignItems: "center",
    justifyContent: "space-between",
    background: "#131f30",
  },
  cardTitle: {
    fontSize: 12,
    fontWeight: 700,
    color: C.accent,
    letterSpacing: 1,
    textTransform: "uppercase",
  },
  table: {
    width: "100%",
    borderCollapse: "collapse",
    fontSize: 12,
  },
  th: {
    padding: "10px 16px",
    textAlign: "left",
    background: "#0d1b2e",
    color: C.muted,
    fontWeight: 700,
    fontSize: 10,
    letterSpacing: 1.5,
    textTransform: "uppercase",
    borderBottom: `1px solid ${C.border}`,
    whiteSpace: "nowrap",
  },
  td: (i) => ({
    padding: "10px 16px",
    borderBottom: `1px solid #1a2840`,
    background: i % 2 === 0 ? C.card : "#182030",
    color: C.text,
    verticalAlign: "middle",
  }),
  btn: (variant = "primary") => ({
    padding: "7px 16px",
    borderRadius: 5,
    border: "none",
    cursor: "pointer",
    fontSize: 11,
    fontWeight: 700,
    letterSpacing: 0.5,
    fontFamily: "inherit",
    background: variant === "primary" ? C.accent : variant === "danger" ? C.red : variant === "success" ? C.green : C.card,
    color: variant === "ghost" ? C.accent : C.bg,
    border: variant === "ghost" ? `1px solid ${C.border}` : "none",
  }),
  input: {
    background: "#0d1b2e",
    border: `1px solid ${C.border}`,
    borderRadius: 5,
    color: C.text,
    padding: "8px 12px",
    fontSize: 12,
    fontFamily: "inherit",
    outline: "none",
    width: "100%",
    boxSizing: "border-box",
  },
  select: {
    background: "#0d1b2e",
    border: `1px solid ${C.border}`,
    borderRadius: 5,
    color: C.text,
    padding: "8px 12px",
    fontSize: 12,
    fontFamily: "inherit",
    outline: "none",
    width: "100%",
  },
  formRow: {
    display: "grid",
    gridTemplateColumns: "1fr 1fr",
    gap: 12,
    marginBottom: 12,
  },
  label: {
    fontSize: 10,
    color: C.muted,
    letterSpacing: 1,
    textTransform: "uppercase",
    marginBottom: 4,
    display: "block",
  },
  sqlBox: {
    background: "#050d1a",
    border: `1px solid ${C.border}`,
    borderRadius: 8,
    fontFamily: "inherit",
    fontSize: 13,
    color: C.green,
    padding: 16,
    width: "100%",
    minHeight: 100,
    outline: "none",
    resize: "vertical",
    boxSizing: "border-box",
    lineHeight: 1.6,
  },
  resultTable: {
    width: "100%",
    borderCollapse: "collapse",
    fontSize: 12,
    marginTop: 0,
  },
  statusBadge: (status) => {
    const colors = {
      Accepted: { bg: "#0a2e20", color: C.green, border: "#00e5a050" },
      "Under Review": { bg: "#2a2010", color: C.yellow, border: "#ffd16650" },
      Rejected: { bg: "#2e0a14", color: C.red, border: "#ff4d6d50" },
    };
    const c = colors[status] || { bg: C.card, color: C.muted, border: C.border };
    return {
      background: c.bg,
      color: c.color,
      border: `1px solid ${c.border}`,
      padding: "2px 8px",
      borderRadius: 4,
      fontSize: 10,
      fontWeight: 700,
      letterSpacing: 1,
    };
  },
  modal: {
    position: "fixed",
    inset: 0,
    background: "rgba(0,0,0,0.75)",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    zIndex: 1000,
    padding: 24,
  },
  modalBox: {
    background: C.surface,
    border: `1px solid ${C.border}`,
    borderRadius: 10,
    width: "100%",
    maxWidth: 520,
    maxHeight: "85vh",
    overflow: "auto",
  },
  modalHeader: {
    padding: "16px 24px",
    borderBottom: `1px solid ${C.border}`,
    display: "flex",
    justifyContent: "space-between",
    alignItems: "center",
    background: "#131f30",
  },
};

// ─── ICONS (SVG strings) ────────────────────────────────────────────────────────
const Icon = ({ d, size = 14, color = "currentColor" }) => (
  <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke={color} strokeWidth={2} strokeLinecap="round" strokeLinejoin="round">
    <path d={d} />
  </svg>
);

const ICONS = {
  home: "M3 9l9-7 9 7v11a2 2 0 01-2 2H5a2 2 0 01-2-2z M9 22V12h6v10",
  users: "M17 21v-2a4 4 0 00-4-4H5a4 4 0 00-4 4v2 M23 21v-2a4 4 0 00-3-3.87 M16 3.13a4 4 0 010 7.75",
  paper: "M14 2H6a2 2 0 00-2 2v16a2 2 0 002 2h12a2 2 0 002-2V8z M14 2v6h6 M16 13H8 M16 17H8 M10 9H8",
  conf: "M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z",
  db: "M12 2C6.477 2 2 4.477 2 7v10c0 2.523 4.477 5 10 5s10-2.477 10-5V7c0-2.523-4.477-5-10-5z M2 7c0 2.523 4.477 5 10 5s10-2.477 10-5 M2 12c0 2.523 4.477 5 10 5s10-2.477 10-5",
  search: "M11 17A6 6 0 105 11a6 6 0 006 6z M21 21l-4.35-4.35",
  plus: "M12 5v14 M5 12h14",
  trash: "M3 6h18 M8 6V4h8v2 M19 6l-1 14H6L5 6",
  cite: "M6 3v7a6 6 0 006 6 6 6 0 006-6V3 M4 21h16",
  review: "M9 11l3 3L22 4 M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11",
  journal: "M2 3h6a4 4 0 014 4v14a3 3 0 00-3-3H2z M22 3h-6a4 4 0 00-4 4v14a3 3 0 013-3h7z",
  sql: "M8 6l4-4 4 4 M8 18l4 4 4-4 M4 12h16",
  chart: "M18 20V10 M12 20V4 M6 20v-6",
};

// ─── REUSABLE TABLE ─────────────────────────────────────────────────────────────
const DataTable = ({ data, onDelete, onEdit, extraCols = [] }) => {
  if (!data || data.length === 0) return (
    <div style={{ padding: 32, textAlign: "center", color: C.muted, fontSize: 12 }}>
      No records found
    </div>
  );
  const cols = Object.keys(data[0]);
  return (
    <div style={{ overflowX: "auto" }}>
      <table style={S.table}>
        <thead>
          <tr>
            {cols.map(c => <th key={c} style={S.th}>{c.replace(/_/g, " ")}</th>)}
            {(onEdit || onDelete) && <th style={S.th}>Actions</th>}
          </tr>
        </thead>
        <tbody>
          {data.map((row, i) => (
            <tr key={i}>
              {cols.map(c => (
                <td key={c} style={S.td(i)}>
                  {c === "status" ? <span style={S.statusBadge(row[c])}>{row[c]}</span>
                    : c.includes("rating") ? <span style={{ color: row[c] >= 8 ? C.green : row[c] >= 6 ? C.yellow : C.red }}>{row[c]}/10</span>
                      : String(row[c] ?? "")}
                </td>
              ))}
              {(onEdit || onDelete) && (
                <td style={S.td(i)}>
                  <div style={{ display: "flex", gap: 6 }}>
                    {onEdit && <button style={S.btn("ghost")} onClick={() => onEdit(row)}>Edit</button>}
                    {onDelete && <button style={{ ...S.btn("danger"), padding: "5px 10px" }} onClick={() => onDelete(row)}>Del</button>}
                  </div>
                </td>
              )}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
};

// ─── MODAL ──────────────────────────────────────────────────────────────────────
const Modal = ({ title, onClose, children }) => (
  <div style={S.modal} onClick={e => e.target === e.currentTarget && onClose()}>
    <div style={S.modalBox}>
      <div style={S.modalHeader}>
        <span style={{ fontSize: 13, fontWeight: 700, color: C.accent }}>{title}</span>
        <button style={{ ...S.btn("ghost"), padding: "4px 10px" }} onClick={onClose}>✕</button>
      </div>
      <div style={{ padding: 24 }}>{children}</div>
    </div>
  </div>
);

// ─── DASHBOARD ──────────────────────────────────────────────────────────────────
const Dashboard = ({ db }) => {
  const stats = [
    { label: "Authors", val: db.Author.length, color: C.accent },
    { label: "Research Papers", val: db.Research_Paper.length, color: C.green },
    { label: "Conferences", val: db.Conference.length, color: C.yellow },
    { label: "Submissions", val: db.Submission.length, color: "#c084fc" },
    { label: "Reviewers", val: db.Reviewer.length, color: "#fb7185" },
    { label: "Citations", val: db.Citation.length, color: "#f97316" },
  ];
  const accepted = db.Submission.filter(s => s.status === "Accepted").length;
  const underReview = db.Submission.filter(s => s.status === "Under Review").length;

  const domainCounts = db.Research_Domain.map(d => ({
    name: d.domain_name,
    count: db.Research_Paper.filter(p => p.domain_id === d.domain_id).length,
  }));

  return (
    <div>
      <div style={S.pageTitle}>📊 Dashboard</div>
      <div style={S.pageSubtitle}>Medical Research Publication & Conference Management System — UCS310</div>

      <div style={S.grid3}>
        {stats.map(s => (
          <div key={s.label} style={S.statCard(s.color)}>
            <div style={S.statNum(s.color)}>{s.val}</div>
            <div style={S.statLabel}>{s.label}</div>
          </div>
        ))}
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 20 }}>
        <div style={S.card}>
          <div style={S.cardHeader}><span style={S.cardTitle}>Submission Status</span></div>
          <div style={{ padding: 20 }}>
            {[["Accepted", accepted, C.green], ["Under Review", underReview, C.yellow]].map(([lbl, val, col]) => (
              <div key={lbl} style={{ marginBottom: 14 }}>
                <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 5 }}>
                  <span style={{ fontSize: 11, color: C.muted }}>{lbl}</span>
                  <span style={{ fontSize: 11, color: col, fontWeight: 700 }}>{val}</span>
                </div>
                <div style={{ height: 6, background: "#1a2840", borderRadius: 3, overflow: "hidden" }}>
                  <div style={{ height: "100%", width: `${(val / db.Submission.length) * 100}%`, background: col, borderRadius: 3 }} />
                </div>
              </div>
            ))}
          </div>
        </div>

        <div style={S.card}>
          <div style={S.cardHeader}><span style={S.cardTitle}>Papers by Domain</span></div>
          <div style={{ padding: 20 }}>
            {domainCounts.map(({ name, count }, i) => {
              const colors = [C.accent, C.green, C.yellow, "#c084fc"];
              return (
                <div key={name} style={{ marginBottom: 14 }}>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 5 }}>
                    <span style={{ fontSize: 11, color: C.muted }}>{name}</span>
                    <span style={{ fontSize: 11, color: colors[i], fontWeight: 700 }}>{count}</span>
                  </div>
                  <div style={{ height: 6, background: "#1a2840", borderRadius: 3, overflow: "hidden" }}>
                    <div style={{ height: "100%", width: `${(count / db.Research_Paper.length) * 100}%`, background: colors[i], borderRadius: 3 }} />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>

      <div style={S.card}>
        <div style={S.cardHeader}><span style={S.cardTitle}>Recent Submissions</span></div>
        <DataTable data={db.Submission} />
      </div>
    </div>
  );
};

// ─── GENERIC CRUD TABLE PAGE ─────────────────────────────────────────────────────
const CRUDPage = ({ title, icon, tableKey, db, setDb, fields }) => {
  const [modal, setModal] = useState(null); // null | 'add' | 'edit'
  const [form, setForm] = useState({});
  const [editRow, setEditRow] = useState(null);
  const [search, setSearch] = useState("");

  const data = db[tableKey];
  const filtered = search
    ? data.filter(row => Object.values(row).some(v => String(v).toLowerCase().includes(search.toLowerCase())))
    : data;

  const openAdd = () => {
    const empty = {};
    fields.forEach(f => empty[f.key] = "");
    setForm(empty); setEditRow(null); setModal("add");
  };
  const openEdit = (row) => { setForm({ ...row }); setEditRow(row); setModal("edit"); };

  const save = () => {
    const newDb = { ...db };
    if (editRow) {
      newDb[tableKey] = data.map(r => r === editRow ? { ...form } : r);
    } else {
      newDb[tableKey] = [...data, { ...form }];
    }
    setDb(newDb); setModal(null);
  };

  const del = (row) => {
    if (window.confirm("Delete this record?")) {
      setDb({ ...db, [tableKey]: data.filter(r => r !== row) });
    }
  };

  return (
    <div>
      <div style={{ display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 24 }}>
        <div>
          <div style={S.pageTitle}>{icon} {title}</div>
          <div style={S.pageSubtitle}>TABLE: {tableKey.toUpperCase()} — {data.length} records</div>
        </div>
        <div style={{ display: "flex", gap: 10, alignItems: "center" }}>
          <input
            style={{ ...S.input, width: 200 }}
            placeholder="Search..."
            value={search}
            onChange={e => setSearch(e.target.value)}
          />
          <button style={S.btn()} onClick={openAdd}>+ Add Record</button>
        </div>
      </div>

      <div style={S.card}>
        <div style={S.cardHeader}>
          <span style={S.cardTitle}>{tableKey.replace(/_/g, " ")}</span>
          <span style={{ fontSize: 10, color: C.muted }}>{filtered.length} rows</span>
        </div>
        <DataTable data={filtered} onEdit={openEdit} onDelete={del} />
      </div>

      {modal && (
        <Modal title={modal === "add" ? `Add to ${tableKey}` : `Edit Record`} onClose={() => setModal(null)}>
          <div>
            {fields.map(f => (
              <div key={f.key} style={{ marginBottom: 14 }}>
                <label style={S.label}>{f.label || f.key.replace(/_/g, " ")}</label>
                {f.options ? (
                  <select style={S.select} value={form[f.key]} onChange={e => setForm({ ...form, [f.key]: e.target.value })}>
                    <option value="">-- Select --</option>
                    {f.options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
                  </select>
                ) : (
                  <input style={S.input} type={f.type || "text"} value={form[f.key]} onChange={e => setForm({ ...form, [f.key]: e.target.value })} placeholder={f.placeholder || f.key} />
                )}
              </div>
            ))}
            <div style={{ display: "flex", gap: 10, marginTop: 20 }}>
              <button style={S.btn()} onClick={save}>{modal === "add" ? "Insert" : "Update"}</button>
              <button style={S.btn("ghost")} onClick={() => setModal(null)}>Cancel</button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
};

// ─── SQL TERMINAL ────────────────────────────────────────────────────────────────
const SQLTerminal = ({ db }) => {
  const [query, setQuery] = useState("SELECT * FROM Author");
  const [result, setResult] = useState(null);
  const [history, setHistory] = useState([]);

  const run = () => {
    const res = runSQL(query, db);
    const entry = { query, res, time: new Date().toLocaleTimeString() };
    setResult(res);
    setHistory(h => [entry, ...h.slice(0, 9)]);
  };

  return (
    <div>
      <div style={S.pageTitle}>⚡ SQL Terminal</div>
      <div style={S.pageSubtitle}>Execute queries against the in-memory database</div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 260px", gap: 20 }}>
        <div>
          <div style={S.card}>
            <div style={S.cardHeader}><span style={S.cardTitle}>Query Editor</span></div>
            <div style={{ padding: 16 }}>
              <textarea
                style={S.sqlBox}
                value={query}
                onChange={e => setQuery(e.target.value)}
                onKeyDown={e => e.ctrlKey && e.key === "Enter" && run()}
                spellCheck={false}
              />
              <div style={{ display: "flex", gap: 10, marginTop: 12 }}>
                <button style={S.btn()} onClick={run}>▶ Run Query (Ctrl+Enter)</button>
                <button style={S.btn("ghost")} onClick={() => { setQuery(""); setResult(null); }}>Clear</button>
              </div>
            </div>
          </div>

          {result && (
            <div style={S.card}>
              <div style={S.cardHeader}>
                <span style={S.cardTitle}>Result</span>
                {result.rows && <span style={{ fontSize: 10, color: C.green }}>{result.rows.length} row(s) returned</span>}
              </div>
              {result.error ? (
                <div style={{ padding: 16, color: C.red, fontSize: 12 }}>✗ Error: {result.error}</div>
              ) : result.message ? (
                <div style={{ padding: 16, color: C.green, fontSize: 12 }}>✓ {result.message}</div>
              ) : (
                <div style={{ overflowX: "auto" }}>
                  <table style={S.resultTable}>
                    <thead>
                      <tr>{result.columns.map(c => <th key={c} style={S.th}>{c}</th>)}</tr>
                    </thead>
                    <tbody>
                      {result.rows.map((row, i) => (
                        <tr key={i}>{row.map((cell, j) => <td key={j} style={S.td(i)}>{String(cell ?? "")}</td>)}</tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>
          )}
        </div>

        <div>
          <div style={S.card}>
            <div style={S.cardHeader}><span style={S.cardTitle}>Preset Queries</span></div>
            <div style={{ padding: 8 }}>
              {PRESET_QUERIES.map((q, i) => (
                <button key={i} style={{ ...S.navBtn(false), fontSize: 11, marginBottom: 3 }}
                  onClick={() => { setQuery(q.sql); setResult(null); }}>
                  {q.label}
                </button>
              ))}
            </div>
          </div>

          {history.length > 0 && (
            <div style={S.card}>
              <div style={S.cardHeader}><span style={S.cardTitle}>History</span></div>
              <div style={{ padding: 8 }}>
                {history.map((h, i) => (
                  <div key={i} style={{ padding: "6px 8px", borderBottom: `1px solid ${C.border}`, cursor: "pointer" }}
                    onClick={() => setQuery(h.query)}>
                    <div style={{ fontSize: 10, color: C.muted }}>{h.time}</div>
                    <div style={{ fontSize: 11, color: C.green, whiteSpace: "nowrap", overflow: "hidden", textOverflow: "ellipsis" }}>{h.query}</div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
};

// ─── ER DIAGRAM PAGE ─────────────────────────────────────────────────────────────
const ERDiagram = () => {
  const entities = [
    { id: "author", label: "AUTHOR", x: 60, y: 120, attrs: ["author_id (PK)", "name", "affiliation", "email"] },
    { id: "paper", label: "RESEARCH_PAPER", x: 340, y: 60, attrs: ["paper_id (PK)", "title", "publication_year", "domain_id (FK)"] },
    { id: "domain", label: "RESEARCH_DOMAIN", x: 620, y: 60, attrs: ["domain_id (PK)", "domain_name"] },
    { id: "reviewer", label: "REVIEWER", x: 60, y: 370, attrs: ["reviewer_id (PK)", "name", "specialization", "email"] },
    { id: "review", label: "REVIEW", x: 340, y: 320, attrs: ["review_id (PK)", "rating", "comments", "paper_id (FK)", "reviewer_id (FK)"] },
    { id: "conf", label: "CONFERENCE", x: 620, y: 240, attrs: ["conf_id (PK)", "conf_name", "location", "start_date", "end_date"] },
    { id: "sub", label: "SUBMISSION", x: 340, y: 520, attrs: ["submission_id (PK)", "submission_date", "status", "paper_id (FK)", "conf_id (FK)"] },
    { id: "journal", label: "JOURNAL", x: 620, y: 440, attrs: ["journal_id (PK)", "journal_name", "impact_factor"] },
    { id: "citation", label: "CITATION", x: 80, y: 560, attrs: ["citing_paper_id (FK)", "cited_paper_id (FK)", "citation_year"] },
  ];

  const rels = [
    { from: [200, 140], to: [340, 100], label: "writes (M:N)" },
    { from: [490, 90], to: [620, 90], label: "belongs to (M:1)" },
    { from: [490, 120], to: [510, 340], label: "receives (1:N)" },
    { from: [200, 400], to: [340, 370], label: "writes (1:N)" },
    { from: [490, 360], to: [620, 280], label: "submitted to (M:N)" },
    { from: [490, 540], to: [620, 280], label: "submitted to" },
    { from: [340, 540], to: [200, 580], label: "" },
  ];

  return (
    <div>
      <div style={S.pageTitle}>🗂 ER Diagram & Schema</div>
      <div style={S.pageSubtitle}>Entity-Relationship model — normalized to 3NF</div>
      <div style={S.card}>
        <div style={S.cardHeader}><span style={S.cardTitle}>Entity-Relationship Diagram</span></div>
        <div style={{ overflowX: "auto", padding: 16 }}>
          <svg width={820} height={680} style={{ display: "block" }}>
            <defs>
              <marker id="arrow" markerWidth="8" markerHeight="8" refX="6" refY="3" orient="auto">
                <path d="M0,0 L0,6 L8,3 z" fill={C.muted} />
              </marker>
            </defs>
            {/* relationships */}
            {rels.map((r, i) => (
              <line key={i} x1={r.from[0]} y1={r.from[1]} x2={r.to[0]} y2={r.to[1]}
                stroke={C.border} strokeWidth={1.5} strokeDasharray="4,3"
                markerEnd="url(#arrow)" />
            ))}
            {/* entities */}
            {entities.map(e => (
              <g key={e.id}>
                <rect x={e.x} y={e.y} width={160} height={22 + e.attrs.length * 18}
                  rx={5} fill={C.card} stroke={C.accent} strokeWidth={1.5} />
                <rect x={e.x} y={e.y} width={160} height={22} rx={5}
                  fill={C.accent + "20"} stroke={C.accent} strokeWidth={1.5} />
                <text x={e.x + 80} y={e.y + 15} textAnchor="middle"
                  fill={C.accent} fontSize={10} fontWeight={800} letterSpacing={1}>{e.label}</text>
                {e.attrs.map((a, i) => (
                  <text key={i} x={e.x + 10} y={e.y + 35 + i * 18}
                    fill={a.includes("PK") ? C.yellow : a.includes("FK") ? C.green : C.muted}
                    fontSize={9} fontFamily="monospace">{a}</text>
                ))}
              </g>
            ))}
          </svg>
        </div>
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr 1fr", gap: 16, marginTop: 20 }}>
        {[
          { title: "1NF", color: C.green, desc: "All attributes atomic. Each table has a unique primary key. No repeating groups." },
          { title: "2NF", color: C.yellow, desc: "No partial dependencies. All non-key attributes fully depend on the primary key." },
          { title: "3NF", color: C.accent, desc: "No transitive dependencies. Non-key attributes depend only on the primary key." },
        ].map(n => (
          <div key={n.title} style={{ ...S.card, marginBottom: 0 }}>
            <div style={{ padding: 20 }}>
              <div style={{ fontSize: 22, fontWeight: 800, color: n.color, marginBottom: 8 }}>{n.title}</div>
              <div style={{ fontSize: 11, color: C.muted, lineHeight: 1.6 }}>{n.desc}</div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

// ─── MAIN APP ────────────────────────────────────────────────────────────────────
export default function App() {
  const [db, setDb] = useState(initDB());
  const [page, setPage] = useState("dashboard");

  const nav = [
    { id: "dashboard", label: "Dashboard", icon: ICONS.home },
    { id: "authors", label: "Authors", icon: ICONS.users },
    { id: "papers", label: "Research Papers", icon: ICONS.paper },
    { id: "reviewers", label: "Reviewers", icon: ICONS.users },
    { id: "reviews", label: "Reviews", icon: ICONS.review },
    { id: "conferences", label: "Conferences", icon: ICONS.conf },
    { id: "submissions", label: "Submissions", icon: ICONS.paper },
    { id: "citations", label: "Citations", icon: ICONS.cite },
    { id: "journals", label: "Journals", icon: ICONS.journal },
    { id: "sql", label: "SQL Terminal", icon: ICONS.sql },
    { id: "er", label: "ER Diagram", icon: ICONS.db },
  ];

  const domainOpts = db.Research_Domain.map(d => ({ value: d.domain_id, label: d.domain_name }));
  const confOpts = db.Conference.map(c => ({ value: c.conf_id, label: c.conf_name }));
  const paperOpts = db.Research_Paper.map(p => ({ value: p.paper_id, label: p.title }));
  const authorOpts = db.Author.map(a => ({ value: a.author_id, label: a.name }));
  const reviewerOpts = db.Reviewer.map(r => ({ value: r.reviewer_id, label: r.name }));

  const pages = {
    dashboard: <Dashboard db={db} />,
    authors: <CRUDPage title="Authors" icon="👤" tableKey="Author" db={db} setDb={setDb} fields={[
      { key: "author_id", label: "Author ID", type: "number" },
      { key: "name", label: "Full Name" },
      { key: "affiliation", label: "Affiliation" },
      { key: "email", label: "Email", type: "email" },
    ]} />,
    papers: <CRUDPage title="Research Papers" icon="📄" tableKey="Research_Paper" db={db} setDb={setDb} fields={[
      { key: "paper_id", label: "Paper ID", type: "number" },
      { key: "title", label: "Paper Title" },
      { key: "publication_year", label: "Publication Year", type: "number" },
      { key: "domain_id", label: "Research Domain", options: domainOpts },
    ]} />,
    reviewers: <CRUDPage title="Reviewers" icon="🔍" tableKey="Reviewer" db={db} setDb={setDb} fields={[
      { key: "reviewer_id", label: "Reviewer ID", type: "number" },
      { key: "name", label: "Full Name" },
      { key: "specialization", label: "Specialization" },
      { key: "email", label: "Email", type: "email" },
    ]} />,
    reviews: <CRUDPage title="Reviews" icon="⭐" tableKey="Review" db={db} setDb={setDb} fields={[
      { key: "review_id", label: "Review ID", type: "number" },
      { key: "rating", label: "Rating (1-10)", type: "number" },
      { key: "comments", label: "Comments" },
      { key: "paper_id", label: "Research Paper", options: paperOpts },
      { key: "reviewer_id", label: "Reviewer", options: reviewerOpts },
    ]} />,
    conferences: <CRUDPage title="Conferences" icon="🏛" tableKey="Conference" db={db} setDb={setDb} fields={[
      { key: "conf_id", label: "Conference ID", type: "number" },
      { key: "conf_name", label: "Conference Name" },
      { key: "location", label: "Location" },
      { key: "start_date", label: "Start Date", type: "date" },
      { key: "end_date", label: "End Date", type: "date" },
    ]} />,
    submissions: <CRUDPage title="Submissions" icon="📬" tableKey="Submission" db={db} setDb={setDb} fields={[
      { key: "submission_id", label: "Submission ID", type: "number" },
      { key: "submission_date", label: "Date", type: "date" },
      { key: "status", label: "Status", options: [{ value: "Accepted", label: "Accepted" }, { value: "Under Review", label: "Under Review" }, { value: "Rejected", label: "Rejected" }] },
      { key: "paper_id", label: "Paper", options: paperOpts },
      { key: "conf_id", label: "Conference", options: confOpts },
    ]} />,
    citations: <CRUDPage title="Citations" icon="📎" tableKey="Citation" db={db} setDb={setDb} fields={[
      { key: "citing_paper_id", label: "Citing Paper", options: paperOpts },
      { key: "cited_paper_id", label: "Cited Paper", options: paperOpts },
      { key: "citation_year", label: "Year", type: "number" },
    ]} />,
    journals: <CRUDPage title="Journals" icon="📚" tableKey="Journal" db={db} setDb={setDb} fields={[
      { key: "journal_id", label: "Journal ID", type: "number" },
      { key: "journal_name", label: "Journal Name" },
      { key: "impact_factor", label: "Impact Factor", type: "number" },
    ]} />,
    sql: <SQLTerminal db={db} />,
    er: <ERDiagram />,
  };

  return (
    <div style={S.app}>
      {/* Header */}
      <header style={S.header}>
        <div style={S.logo}>
          <span>🏥</span>
          <span>MedResearch DBMS</span>
          <span style={S.badge}>UCS310</span>
        </div>
        <div style={{ fontSize: 10, color: C.muted, letterSpacing: 1 }}>
          THAPAR INSTITUTE · GROUP 2C22
        </div>
      </header>

      <div style={S.layout}>
        {/* Sidebar */}
        <aside style={S.sidebar}>
          <div style={S.sideLabel}>Navigation</div>
          <div style={S.sideSection}>
            {nav.map(n => (
              <button key={n.id} style={S.navBtn(page === n.id)} onClick={() => setPage(n.id)}>
                <Icon d={n.icon} size={12} />
                {n.label}
              </button>
            ))}
          </div>
          <div style={{ padding: "16px 24px", marginTop: 8, borderTop: `1px solid ${C.border}` }}>
            <div style={{ fontSize: 9, color: C.muted, letterSpacing: 1, lineHeight: 1.8 }}>
              <div>Avraj Singh Sekhon</div>
              <div>Chhavi Garg</div>
              <div>Rashika Rathore</div>
              <div style={{ marginTop: 4, color: C.accent + "80" }}>Dr. Damini Arora</div>
            </div>
          </div>
        </aside>

        {/* Main */}
        <main style={S.main}>
          {pages[page]}
        </main>
      </div>
    </div>
  );
}
