import React, { useEffect, useMemo, useState } from "react";

function getBackendUrl() {
  const cfg = window.__CONFIG__ || {};
  return (cfg.BACKEND_URL || "").replace(/\/+$/, "");
}

export default function App() {
  const backend = useMemo(() => getBackendUrl(), []);
  const [categories, setCategories] = useState([]);
  const [products, setProducts] = useState([]);
  const [page, setPage] = useState(0);
  const size = 10;
  const [total, setTotal] = useState(0);
  const [err, setErr] = useState("");

  async function load() {
    setErr("");
    try {
      if (!backend) throw new Error("BACKEND_URL não definido em /config.js");

      const cats = await fetch(`${backend}/api/categories`).then(r => r.json());
      setCategories(Array.isArray(cats) ? cats : []);

      const prods = await fetch(`${backend}/api/products?page=${page}&size=${size}`).then(r => r.json());
      setProducts(Array.isArray(prods?.items) ? prods.items : []);
      setTotal(Number(prods?.total || 0));
    } catch (e) {
      setErr(String(e?.message || e));
    }
  }

  useEffect(() => { load(); }, [page]); // eslint-disable-line

  const totalPages = Math.max(Math.ceil(total / size), 1);

  return (
    <div style={{ fontFamily: "system-ui, sans-serif", padding: 24, maxWidth: 1000, margin: "0 auto" }}>
      <h1 style={{ marginTop: 0 }}>Catalog UI (Mock)</h1>

      <div style={{ padding: 12, border: "1px solid #ddd", borderRadius: 8, marginBottom: 16 }}>
        <div><b>Backend:</b> {backend || "(não definido)"} </div>
        {err ? <div style={{ color: "crimson", marginTop: 8 }}><b>Erro:</b> {err}</div> : null}
      </div>

      <div style={{ display: "grid", gridTemplateColumns: "1fr 2fr", gap: 16 }}>
        <section style={{ padding: 12, border: "1px solid #ddd", borderRadius: 8 }}>
          <h2 style={{ marginTop: 0 }}>Categorias</h2>
          <ul>
            {categories.map((c, i) => <li key={c?._id || i}>{c?.name || JSON.stringify(c)}</li>)}
          </ul>
        </section>

        <section style={{ padding: 12, border: "1px solid #ddd", borderRadius: 8 }}>
          <h2 style={{ marginTop: 0 }}>Produtos</h2>

          <div style={{ display: "flex", gap: 8, alignItems: "center", marginBottom: 12 }}>
            <button onClick={() => setPage(p => Math.max(p - 1, 0))} disabled={page === 0}>Anterior</button>
            <div>Página <b>{page + 1}</b> de <b>{totalPages}</b> (total: {total})</div>
            <button onClick={() => setPage(p => Math.min(p + 1, totalPages - 1))} disabled={page >= totalPages - 1}>Próxima</button>
            <button onClick={load} style={{ marginLeft: "auto" }}>Recarregar</button>
          </div>

          <table width="100%" cellPadding="8" style={{ borderCollapse: "collapse" }}>
            <thead>
              <tr>
                <th align="left" style={{ borderBottom: "1px solid #ddd" }}>Nome</th>
                <th align="left" style={{ borderBottom: "1px solid #ddd" }}>Categoria</th>
                <th align="right" style={{ borderBottom: "1px solid #ddd" }}>Preço</th>
                <th align="left" style={{ borderBottom: "1px solid #ddd" }}>SKU</th>
              </tr>
            </thead>
            <tbody>
              {products.map((p, i) => (
                <tr key={p?._id || i}>
                  <td style={{ borderBottom: "1px solid #f0f0f0" }}>{p?.name}</td>
                  <td style={{ borderBottom: "1px solid #f0f0f0" }}>{p?.category}</td>
                  <td style={{ borderBottom: "1px solid #f0f0f0" }} align="right">{p?.price}</td>
                  <td style={{ borderBottom: "1px solid #f0f0f0" }}>{p?.sku}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      </div>
    </div>
  );
}
