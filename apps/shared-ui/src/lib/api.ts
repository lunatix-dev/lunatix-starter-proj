import { get } from 'svelte/store';
import { apiBaseUrl } from './config';

export interface StatusResponse {
    status: string;
    version: string;
    uptime_seconds: number;
}

/**
 * GET /status — check if the C++ server is alive.
 */
export async function getStatus(): Promise<StatusResponse> {
    return apiGet<StatusResponse>('/status');
}

/**
 * Generic GET helper that reads the current API base URL from the store.
 */
export async function apiGet<T>(path: string): Promise<T> {
    const base = get(apiBaseUrl);
    const res = await fetch(`${base}${path}`);
    if (!res.ok) throw new Error(`API ${res.status}: ${res.statusText}`);
    return res.json();
}

/**
 * Generic POST helper.
 */
export async function apiPost<T>(path: string, body: unknown): Promise<T> {
    const base = get(apiBaseUrl);
    const res = await fetch(`${base}${path}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(body),
    });
    if (!res.ok) throw new Error(`API ${res.status}: ${res.statusText}`);
    return res.json();
}
