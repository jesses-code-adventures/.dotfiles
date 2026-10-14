/**
 * Warning logger for kdco registry plugins.
 *
 * Provides a unified interface for logging warnings that works with
 * both the OpenCode client (when available) and console fallback.
 *
 * @module kdco-primitives/log-warn
 */

/**
 * Log a warning message via OpenCode client or console fallback.
 *
 * Uses the OpenCode logging API when a client is available, which integrates
 * with the OpenCode UI log panel. Falls back to console.warn for CLI contexts
 * or when no client is provided.
 *
 * @param client - Optional OpenCode client for proper logging integration
 * @param service - Service name for log categorization (e.g., "worktree", "delegation")
 * @param message - Warning message to log
 *
 * @example
 * ```ts
 * // With client - logs to OpenCode UI
 * logWarn(client, "delegation", "Task timed out after 30s")
 *
 * // Without client - logs to console
 * logWarn(undefined, "delegation", "Task timed out after 30s")
 * ```
 */
export function logWarn(
	client: unknown,
	service: string,
	message: string,
): void {
	const app =
		client && typeof client === "object" && "app" in client
			? (client.app as { log?: (input: unknown) => Promise<unknown> })
			: undefined

	// Guard: No compatible client logger available, use console fallback.
	if (typeof app?.log !== "function") {
		console.warn(`[${service}] ${message}`)
		return
	}

	// Legacy-compatible path for clients that still expose app.log.
	app
		.log({
			body: { service, level: "warn", message },
		})
		.catch(() => {
			// Silently ignore logging failures - don't disrupt caller
		})
}
