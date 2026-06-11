import { getApiBaseUrl } from '../../lib/api';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const headline = typeof req.body?.headline === 'string' ? req.body.headline : '';
  if (!headline.trim()) {
    return res.status(400).json({ error: 'Headline is required' });
  }

  const params = new URLSearchParams({ headline });

  try {
    const upstream = await fetch(`${getApiBaseUrl()}/api/sometimes`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: params.toString(),
    });

    const data = await upstream.json().catch(() => ({}));
    return res.status(upstream.status).json(data);
  } catch (err) {
    return res.status(502).json({ error: 'Upstream API unreachable' });
  }
}
