# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```sh
swift build
swift test
swift test --filter AsyncClientTests
swift test --filter InterceptorTests
```

## What this is

A generic, transport-layer async/await HTTP client (`AsyncNetworkClient`) with a composable interceptor chain for cross-cutting concerns (auth, caching, logging, rate limiting). It knows nothing about Discogs, OAuth 1.0a, or any specific API **by design** — this package ships only generic example/default interceptors; anything API-specific (Discogs OAuth 1.0a signing, in particular) is defined and injected entirely by the consumer (`VLDiscogsClient`), not by this package or `VLOAuthFlowCoordinator`. Depends on `VLDebugLogger` for its internal request/response logging.

## Architecture

- **`AsyncNetworkClient`** (`Public/AsyncNetworkClient.swift`) — the actor doing the actual transport (`URLSessionProtocol`, defaults to `URLSession.shared`). Handles transport only: runs a request through the interceptor chain, returns a raw `NetworkResponse`. Callers decode the body themselves via `NetworkResponse.decode(_:using:)` — this client does not do response decoding for you.
- **`Interceptor`** (`Public/Protocols/Interceptor.swift`) — the extension point: `intercept(_ request:) async throws -> URLRequest` (pre-send) and `intercept(_ response:data:) async throws -> Data?` (post-receive). Interceptors are chained via `InterceptorChain` (an actor) and run in the order added — order matters (e.g. an auth interceptor needs to run before a logging interceptor if you want the final signed headers logged).
- **`RequestConfiguration`** — describes one request (URL, method, headers, body, retry count/delay, cache policy).
- **Retry** is built into `AsyncNetworkClient.request(for:)` via `withRetry(config.retryCount, delay: config.retryDelay)` — configured per-request, not globally.

### Built-in interceptors assume Bearer-token auth — not what Discogs OAuth 1.0a needs

`AuthenticationInterceptor` (`Private/Interceptors/AuthenticationInterceptor.swift`) sets `Authorization: Bearer <token>` from a `TokenManager` (an actor protocol with `getValidToken()`/`refreshToken()`). This is an OAuth 2.0/bearer-token pattern. **Discogs uses OAuth 1.0a** (per-request HMAC/RSA signatures, not a static bearer token) — this built-in interceptor is not what `VLDiscogsClient` actually uses for Discogs API calls. `VLDiscogsClient` defines its own `OAuthInterceptor` (conforming to this package's `Interceptor` protocol, wrapping `VLOAuthFlowCoordinator`'s signing via an internal `OAuthTokenManager` adapter) and injects it directly into an `InterceptorChain` it constructs itself (`VLDiscogsClient`'s private `NetworkClientManager`) — this package and `VLOAuthFlowCoordinator` are not aware of each other or of Discogs at all. Don't assume `AuthenticationInterceptor`/`TokenManager` are in the path for Discogs traffic just because they exist in this package — they aren't used for it.

`AuthenticationInterceptor` also treats HTTP 401 as "refresh and retry" by throwing `InterceptorError.shouldRetryRequest` — again, this is the bearer-token refresh pattern, not applicable to OAuth 1.0a's signature-based auth.

### RateLimitInterceptor is a local, in-memory sliding window — not Discogs-rate-limit-aware

`RateLimitInterceptor` (`Private/Interceptors/RateLimitInterceptor.swift`) enforces a simple client-side cap (default 60 req/min) by tracking request timestamps in memory and `Task.sleep`-ing when the window is full. It has no knowledge of Discogs's actual `X-Discogs-Ratelimit-*` response headers — it's a blunt, configured-in-advance ceiling, not an adaptive limiter reacting to server-reported limits. Discogs's actual authenticated ceiling is **60 req/min** (25 req/min unauthenticated) — tight enough that this interceptor's default cap sits right at the limit, not safely under it. If Discogs's real-time rate limit state needs to be respected (adaptive throttling off `X-Discogs-Ratelimit-Remaining`), that has to be implemented as a different interceptor or handled by the caller — don't assume this one reads response headers.

### Logging goes through VLDebugLogger automatically

`AsyncNetworkClient` holds a `VLDebugLogger` (defaults to `.shared`) and logs requests/responses through it — meaning `Authorization`/`X-API-Key` headers are redacted automatically (see `VLDebugLogger`'s CLAUDE.md), but response bodies are not redacted by default.
