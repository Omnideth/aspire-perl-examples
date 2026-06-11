import { useState } from 'react';
import { useRouter } from 'next/router';
import { getApiBaseUrl, getSummary, postHeadline } from '../lib/api';

export async function getServerSideProps() {
  try {
    const summary = await getSummary();

    return {
      props: {
        summary,
        apiBaseUrl: getApiBaseUrl(),
      },
    };
  } catch (error) {
    return {
      props: {
        error: error instanceof Error ? error.message : 'Unknown error',
        apiBaseUrl: getApiBaseUrl(),
      },
    };
  }
}

function sanitize(value) {
  return value
    .replace(/[<>&"'`]/g, '')
    .replace(/\s+/g, ' ')
    .trim()
    .slice(0, 200);
}

export default function Home({ apiBaseUrl, error, summary }) {
  const router = useRouter();
  const [modalOpen, setModalOpen] = useState(false);
  const [inputValue, setInputValue] = useState('');
  const [submitting, setSubmitting] = useState(false);
  const [formError, setFormError] = useState('');

  function openModal() {
    setInputValue('');
    setFormError('');
    setModalOpen(true);
  }

  function closeModal() {
    setModalOpen(false);
  }

  async function handleSubmit(e) {
    e.preventDefault();
    const headline = sanitize(inputValue);
    if (!headline) {
      setFormError('Please enter a headline.');
      return;
    }
    setSubmitting(true);
    setFormError('');
    try {
      await postHeadline(headline);
      closeModal();
      router.replace(router.asPath);
    } catch (err) {
      setFormError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <main className="shell">
      <section className="hero">
        <p className="eyebrow">Perl + Next.js</p>
        <h1>Server-rendered React, Perl API, and Postgres in one Aspire graph.</h1>
        <p className="lede">
          The page is rendered by Next.js, the data comes from a Mojolicious API,
          and Aspire injects the service endpoint into the frontend process.
        </p>
        <div className="hero-footer">
          <div className="meta">
            <span>API base URL</span>
            <code>{apiBaseUrl}</code>
          </div>
          <button className="btn-add" onClick={openModal}>+ Add entry</button>
        </div>
      </section>

      {error ? (
        <section className="card error">
          <h2>API unavailable</h2>
          <p>{error}</p>
        </section>
      ) : (
        <section className="grid">
          <article className="card accent">
            <h2>Total rows</h2>
            <p className="count">{summary.count}</p>
            <p>{summary.source}</p>
          </article>

          <article className="card">
            <h2>Latest entries</h2>
            <ul className="items">
              {summary.items.map((item) => (
                <li key={`${item.headline}-${item.created_at}`}>
                  <strong>{item.headline}</strong>
                  <span>{item.created_at}</span>
                </li>
              ))}
            </ul>
          </article>
        </section>
      )}

      {modalOpen && (
        <div className="modal-backdrop" onClick={closeModal}>
          <div className="modal" role="dialog" aria-modal="true" aria-labelledby="modal-title" onClick={(e) => e.stopPropagation()}>
            <h2 id="modal-title">New headline</h2>
            <form onSubmit={handleSubmit}>
              <input
                className="modal-input"
                type="text"
                placeholder="Enter a headline…"
                maxLength={200}
                value={inputValue}
                onChange={(e) => setInputValue(e.target.value)}
                autoFocus
              />
              {formError && <p className="modal-error">{formError}</p>}
              <div className="modal-actions">
                <button type="button" className="btn-cancel" onClick={closeModal}>Cancel</button>
                <button type="submit" className="btn-submit" disabled={submitting}>
                  {submitting ? 'Saving…' : 'Save'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </main>
  );
}