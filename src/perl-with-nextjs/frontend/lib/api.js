const fallbackApiBaseUrl = 'http://localhost:8080';

export function getApiBaseUrl() {
  return process.env.services__api__http__0
    || process.env.services__api__https__0
    || fallbackApiBaseUrl;
}

export async function getSummary() {
  const response = await fetch(`${getApiBaseUrl()}/api/summary`, {
    cache: 'no-store',
  });

  if (!response.ok) {
    throw new Error(`Perl API returned ${response.status}`);
  }

  return response.json();
}

export async function postHeadline(headline) {
  const params = new URLSearchParams({ headline });
  const response = await fetch('/api/sometimes', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: params.toString(),
  });

  if (!response.ok) {
    const data = await response.json().catch(() => ({}));
    throw new Error(data.error || `API returned ${response.status}`);
  }

  return response.json();
}