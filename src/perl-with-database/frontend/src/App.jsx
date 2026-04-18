import { useState, useEffect, useCallback } from 'react';

export default function App() {
  const [data, setData] = useState(null);
  const [error, setError] = useState(null);
  const [loading, setLoading] = useState(false);

  const fetchActivity = useCallback(async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch('/api/activity?limit=50');
      if (!res.ok) throw new Error(`HTTP ${res.status}`);
      setData(await res.json());
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }, []);

  useEffect(() => { fetchActivity(); }, [fetchActivity]);

  return (
    <div className="container">
      <header>
        <h1>Activity Dashboard</h1>
        <button onClick={fetchActivity} disabled={loading}>
          {loading ? 'Refreshing…' : '↻ Refresh'}
        </button>
      </header>

      {error && <div className="error">Error: {error}</div>}

      {data && (
        <>
          <p className="count">{data.count} record{data.count !== 1 ? 's' : ''}</p>
          <table>
            <thead>
              <tr>
                <th>Date</th>
                <th>User</th>
                <th>Tick Count</th>
              </tr>
            </thead>
            <tbody>
              {data.items.map((row, i) => (
                <tr key={i}>
                  <td>{new Date(row.insertdate).toLocaleString()}</td>
                  <td>{row.username}</td>
                  <td className="number">{row.tick_count}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </>
      )}

      {!data && !error && loading && <p className="loading">Loading…</p>}
    </div>
  );
}
