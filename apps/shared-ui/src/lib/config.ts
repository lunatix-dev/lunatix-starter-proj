import { writable } from 'svelte/store';

/**
 * Reactive store for the API base URL.
 *
 * - Web mode:    VITE_API_URL is baked in at build time (e.g. https://api.example.com)
 * - Desktop:     defaults to localhost:8080, can be switched at runtime via Tauri commands
 */
export const apiBaseUrl = writable<string>(
    import.meta.env.VITE_API_URL ?? 'http://localhost:8080'
);

/**
 * Whether the app is running inside Tauri (desktop) or the browser (web).
 */
export const isTauri: boolean =
    typeof window !== 'undefined' && '__TAURI__' in window;
