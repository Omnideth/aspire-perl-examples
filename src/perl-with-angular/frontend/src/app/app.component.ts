import { CommonModule } from '@angular/common';
import { HttpClient } from '@angular/common/http';
import { Component, inject, signal } from '@angular/core';
import { firstValueFrom } from 'rxjs';

type ApiInfo = {
  framework: string;
  message: string;
  port: string;
  source: string;
  timestamp: string;
};

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [CommonModule],
  template: `
    <main class="shell">
      <section class="hero">
        <p class="eyebrow">Perl + Angular</p>
        <h1>Angular dev server proxying to a Mojolicious API.</h1>
        <p class="lede">
          The SPA stays small, the Perl API owns the server behavior, and Aspire
          injects the service endpoint into the Angular process.
        </p>
      </section>

      <section class="panel" *ngIf="!error(); else failure">
        <div class="badge">{{ info()?.framework }}</div>
        <h2>{{ info()?.message }}</h2>
        <dl>
          <div>
            <dt>Backend</dt>
            <dd>{{ info()?.source }}</dd>
          </div>
          <div>
            <dt>Port</dt>
            <dd>{{ info()?.port }}</dd>
          </div>
          <div>
            <dt>Timestamp</dt>
            <dd>{{ info()?.timestamp }}</dd>
          </div>
        </dl>
      </section>

      <ng-template #failure>
        <section class="panel error">
          <h2>API unavailable</h2>
          <p>{{ error() }}</p>
        </section>
      </ng-template>
    </main>
  `,
  styles: [`
    .shell {
      max-width: 980px;
      margin: 0 auto;
      padding: 56px 20px;
    }

    .hero h1 {
      margin: 0;
      max-width: 11ch;
      font-size: clamp(2.7rem, 7vw, 5rem);
      line-height: 0.94;
    }

    .eyebrow {
      margin: 0 0 12px;
      letter-spacing: 0.16em;
      text-transform: uppercase;
      color: #c2410c;
      font-size: 0.82rem;
    }

    .lede {
      max-width: 58ch;
      color: #5b6573;
      line-height: 1.6;
    }

    .panel {
      margin-top: 28px;
      padding: 24px;
      border-radius: 24px;
      background: rgba(255, 255, 255, 0.78);
      border: 1px solid rgba(15, 23, 42, 0.1);
      box-shadow: 0 22px 64px rgba(15, 23, 42, 0.12);
    }

    .badge {
      display: inline-block;
      margin-bottom: 12px;
      padding: 8px 12px;
      border-radius: 999px;
      background: rgba(231, 111, 81, 0.14);
      color: #9a3412;
      font-weight: 600;
    }

    dl {
      display: grid;
      gap: 16px;
      margin: 24px 0 0;
    }

    dt {
      font-size: 0.82rem;
      text-transform: uppercase;
      letter-spacing: 0.14em;
      color: #5b6573;
    }

    dd {
      margin: 6px 0 0;
      font-size: 1.02rem;
    }

    .error {
      border-color: rgba(153, 27, 27, 0.18);
    }
  `],
})
export class AppComponent {
  private readonly httpClient = inject(HttpClient);

  protected readonly error = signal('');
  protected readonly info = signal<ApiInfo | null>(null);

  public constructor() {
    void this.load();
  }

  private async load(): Promise<void> {
    try {
      const info = await firstValueFrom(this.httpClient.get<ApiInfo>('/api/info'));
      this.info.set(info);
      this.error.set('');
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Unknown error';
      this.error.set(message);
    }
  }
}