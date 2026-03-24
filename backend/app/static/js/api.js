/**
 * API client with JWT token management.
 * All methods return parsed JSON or throw on error.
 */
const API = (() => {
  const TOKEN_KEY = 'kalender_token';
  const USER_KEY = 'kalender_user';

  function getToken() { return localStorage.getItem(TOKEN_KEY); }
  function setToken(token) { localStorage.setItem(TOKEN_KEY, token); }
  function clearToken() { localStorage.removeItem(TOKEN_KEY); localStorage.removeItem(USER_KEY); }
  function getUser() { try { const u = localStorage.getItem(USER_KEY); return u ? JSON.parse(u) : null; } catch { return null; } }
  function setUser(user) { localStorage.setItem(USER_KEY, JSON.stringify(user)); }

  async function request(method, path, body) {
    const headers = { 'Content-Type': 'application/json' };
    const token = getToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;

    const opts = { method, headers };
    if (body !== undefined) opts.body = JSON.stringify(body);

    const res = await fetch(path, opts);

    if (res.status === 204) return null;
    if (!res.ok) {
      const data = await res.json().catch(() => ({}));
      if (res.status === 401 && token && !path.includes('/auth/login')) {
        clearToken();
        location.reload();
      }
      throw new Error(data.detail || `Fehler ${res.status}`);
    }
    return res.json();
  }

  return {
    getToken, setToken, clearToken, getUser, setUser,
    get:    (path) => request('GET', path),
    post:   (path, body) => request('POST', path, body),
    put:    (path, body) => request('PUT', path, body),
    patch:  (path, body) => request('PATCH', path, body),
    delete: (path) => request('DELETE', path),
  };
})();
