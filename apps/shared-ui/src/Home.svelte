<script lang="ts">
  import { onMount } from 'svelte';
  import { getStatus, type StatusResponse } from '$lib/api';
  import { apiBaseUrl, isTauri } from '$lib/config';
  import { invoke } from '@tauri-apps/api/tauri';

  let status = $state<StatusResponse | null>(null);
  let error = $state<string | null>(null);
  let loading = $state(true);
  let remoteUrl = $state('');
  let currentMode = $state<'standalone' | 'remote'>('standalone');
  let currentBaseUrl = $state('');

  // Subscribe to store
  apiBaseUrl.subscribe((url) => {
    currentBaseUrl = url;
  });

  async function fetchStatus() {
    loading = true;
    error = null;
    try {
      status = await getStatus();
    } catch (e) {
      error = e instanceof Error ? e.message : String(e);
      status = null;
    } finally {
      loading = false;
    }
  }

  async function switchToStandalone() {
    if (isTauri) {
      try {
        await invoke('set_standalone_mode');
      } catch (e) {
        error = String(e);
        return;
      }
    }
    apiBaseUrl.set('http://localhost:8080');
    currentMode = 'standalone';
    fetchStatus();
  }

  async function switchToRemote() {
    if (!remoteUrl.trim()) return;
    const url = remoteUrl.trim().replace(/\/$/, '');
    
    if (isTauri) {
      try {
        await invoke('set_remote_mode', { url });
      } catch (e) {
        error = String(e);
        return;
      }
    }
    
    apiBaseUrl.set(url);
    currentMode = 'remote';
    fetchStatus();
  }

  onMount(() => {
    fetchStatus();
    // Auto-refresh every 5 seconds
    const interval = setInterval(fetchStatus, 5000);
    return () => clearInterval(interval);
  });
</script>

<div class="container">
  <header>
    <div class="logo">
      <span class="logo-icon">◈</span>
      <h1>Lunatix</h1>
    </div>
    <p class="subtitle">Tauri + Svelte + C++ Server Demo</p>
  </header>

  <section class="status-card">
    <div class="card-header">
      <h2>Server Status</h2>
      <div class="badge" class:badge-success={status?.status === 'ok'} class:badge-error={!!error}>
        {#if loading}
          ⏳ Checking…
        {:else if status}
          ● Online
        {:else}
          ✕ Offline
        {/if}
      </div>
    </div>

    {#if status}
      <div class="stats-grid">
        <div class="stat">
          <span class="stat-label">Status</span>
          <span class="stat-value success">{status.status}</span>
        </div>
        <div class="stat">
          <span class="stat-label">Version</span>
          <span class="stat-value">{status.version}</span>
        </div>
        <div class="stat">
          <span class="stat-label">Uptime</span>
          <span class="stat-value">{status.uptime_seconds}s</span>
        </div>
        <div class="stat">
          <span class="stat-label">Endpoint</span>
          <span class="stat-value mono">{currentBaseUrl}</span>
        </div>
      </div>
    {:else if error}
      <div class="error-box">
        <p>{error}</p>
        <p class="hint">Is the C++ server running at <code>{currentBaseUrl}</code>?</p>
      </div>
    {/if}

    <button class="btn btn-secondary" onclick={fetchStatus} disabled={loading}>
      {loading ? 'Refreshing…' : '↻ Refresh'}
    </button>
  </section>

  <section class="mode-card">
    <h2>Connection Mode</h2>
    <p class="mode-hint">
      {#if isTauri}
        Running in <strong>Tauri desktop</strong> — switch between local sidecar and remote server.
      {:else}
        Running in <strong>browser</strong> — configure which C++ server to connect to.
      {/if}
    </p>

    <div class="mode-controls">
      <button
        class="btn"
        class:btn-active={currentMode === 'standalone'}
        onclick={switchToStandalone}
      >
        🖥 Standalone (localhost)
      </button>

      <div class="remote-input">
        <input
          type="text"
          bind:value={remoteUrl}
          placeholder="https://api.example.com"
          onkeydown={(e) => e.key === 'Enter' && switchToRemote()}
        />
        <button
          class="btn"
          class:btn-active={currentMode === 'remote'}
          onclick={switchToRemote}
        >
          🌐 Connect Remote
        </button>
      </div>
    </div>
  </section>

  <footer>
    <p>Mode: <code>{currentMode}</code> · API: <code>{currentBaseUrl}</code></p>
  </footer>
</div>

<style>
  .container {
    width: 100%;
    max-width: 600px;
    display: flex;
    flex-direction: column;
    gap: 1.5rem;
  }

  header {
    text-align: center;
  }

  .logo {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 0.75rem;
    margin-bottom: 0.5rem;
  }

  .logo-icon {
    font-size: 2rem;
    color: var(--accent);
    filter: drop-shadow(0 0 8px var(--accent-glow));
    animation: pulse 2s ease-in-out infinite;
  }

  @keyframes pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.6; }
  }

  h1 {
    font-size: 2rem;
    font-weight: 700;
    letter-spacing: -0.02em;
    background: linear-gradient(135deg, var(--accent), #a78bfa);
    -webkit-background-clip: text;
    -webkit-text-fill-color: transparent;
    background-clip: text;
  }

  .subtitle {
    color: var(--text-secondary);
    font-size: 0.9rem;
    font-weight: 300;
  }

  .status-card, .mode-card {
    background: var(--bg-card);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    padding: 1.5rem;
    display: flex;
    flex-direction: column;
    gap: 1rem;
    transition: border-color 0.2s;
  }

  .status-card:hover, .mode-card:hover {
    border-color: var(--accent);
    box-shadow: 0 0 20px var(--accent-glow);
  }

  .card-header {
    display: flex;
    align-items: center;
    justify-content: space-between;
  }

  h2 {
    font-size: 1.1rem;
    font-weight: 600;
  }

  .badge {
    font-size: 0.8rem;
    font-weight: 500;
    padding: 0.25rem 0.75rem;
    border-radius: 9999px;
    background: var(--bg-primary);
    color: var(--text-secondary);
  }

  .badge-success {
    color: var(--success);
    background: rgba(74, 222, 128, 0.1);
  }

  .badge-error {
    color: var(--error);
    background: rgba(248, 113, 113, 0.1);
  }

  .stats-grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 0.75rem;
  }

  .stat {
    display: flex;
    flex-direction: column;
    gap: 0.2rem;
  }

  .stat-label {
    font-size: 0.75rem;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--text-secondary);
  }

  .stat-value {
    font-size: 1rem;
    font-weight: 500;
  }

  .stat-value.success {
    color: var(--success);
  }

  .stat-value.mono {
    font-family: 'JetBrains Mono', monospace;
    font-size: 0.85rem;
    word-break: break-all;
  }

  .error-box {
    background: rgba(248, 113, 113, 0.08);
    border: 1px solid rgba(248, 113, 113, 0.2);
    border-radius: 8px;
    padding: 1rem;
    color: var(--error);
  }

  .error-box .hint {
    color: var(--text-secondary);
    font-size: 0.85rem;
    margin-top: 0.5rem;
  }

  .error-box code {
    background: var(--bg-primary);
    padding: 0.1rem 0.4rem;
    border-radius: 4px;
    font-size: 0.85rem;
  }

  .btn {
    padding: 0.6rem 1.2rem;
    border-radius: 8px;
    border: 1px solid var(--border);
    background: var(--bg-primary);
    color: var(--text-primary);
    font-family: var(--font);
    font-size: 0.9rem;
    cursor: pointer;
    transition: all 0.15s;
  }

  .btn:hover {
    background: var(--bg-card-hover);
    border-color: var(--accent);
  }

  .btn:disabled {
    opacity: 0.5;
    cursor: not-allowed;
  }

  .btn-secondary {
    align-self: flex-start;
  }

  .btn-active {
    background: var(--accent);
    border-color: var(--accent);
    color: white;
    box-shadow: 0 0 12px var(--accent-glow);
  }

  .mode-hint {
    color: var(--text-secondary);
    font-size: 0.85rem;
  }

  .mode-controls {
    display: flex;
    flex-direction: column;
    gap: 0.75rem;
  }

  .remote-input {
    display: flex;
    gap: 0.5rem;
  }

  .remote-input input {
    flex: 1;
    padding: 0.6rem 1rem;
    border-radius: 8px;
    border: 1px solid var(--border);
    background: var(--bg-primary);
    color: var(--text-primary);
    font-family: var(--font);
    font-size: 0.9rem;
    outline: none;
    transition: border-color 0.15s;
  }

  .remote-input input:focus {
    border-color: var(--accent);
  }

  .remote-input input::placeholder {
    color: var(--text-secondary);
  }

  footer {
    text-align: center;
    color: var(--text-secondary);
    font-size: 0.8rem;
  }

  footer code {
    background: var(--bg-card);
    padding: 0.1rem 0.4rem;
    border-radius: 4px;
    font-size: 0.8rem;
  }
</style>
