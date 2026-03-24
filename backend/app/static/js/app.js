/**
 * Main application: auth flow, navigation, modal system, shared state.
 */
const App = (() => {
  let categories = [];
  let members = [];
  let isSetupMode = false;

  const DIFFICULTY_LABELS = { easy: 'Einfach', medium: 'Mittel', hard: 'Aufwendig' };
  const DIFFICULTY_CLASS = { easy: 'diff-easy', medium: 'diff-medium', hard: 'diff-hard' };

  /* ── Auth ────────────────────────────────────── */
  function updateAuthUI() {
    document.getElementById('auth-subtitle').textContent = isSetupMode ? 'Registrieren' : 'Anmelden';
    document.getElementById('auth-btn').textContent = isSetupMode ? 'Account erstellen' : 'Anmelden';
    document.getElementById('auth-toggle').innerHTML = isSetupMode
      ? 'Bereits ein Account? <a href="#" id="auth-toggle-link">Anmelden</a>'
      : 'Noch kein Account? <a href="#" id="auth-toggle-link">Registrieren</a>';
    document.getElementById('auth-toggle-link').addEventListener('click', (e) => {
      e.preventDefault();
      isSetupMode = !isSetupMode;
      document.getElementById('auth-error').textContent = '';
      updateAuthUI();
    });
  }

  function initAuth() {
    updateAuthUI();

    document.getElementById('auth-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      const errEl = document.getElementById('auth-error');
      errEl.textContent = '';
      const username = document.getElementById('auth-user').value.trim();
      const password = document.getElementById('auth-pass').value;
      try {
        if (isSetupMode) {
          await API.post('/api/auth/register', { username, password });
        }
        const data = await API.post('/api/auth/login', { username, password });
        API.setToken(data.access_token);
        const user = await API.get('/api/auth/me');
        API.setUser(user);
        showApp();
      } catch (err) {
        errEl.textContent = err.message;
      }
    });
  }

  function showAuth() {
    document.getElementById('auth-screen').classList.remove('hidden');
    document.getElementById('app-screen').classList.add('hidden');
  }

  async function showApp() {
    const user = API.getUser();
    if (!user || !user.family_id) {
      showFamilyOnboarding();
      return;
    }

    document.getElementById('auth-screen').classList.add('hidden');
    document.getElementById('family-screen').classList.add('hidden');
    document.getElementById('app-screen').classList.remove('hidden');
    document.getElementById('user-display').textContent = user ? user.username : '';
    await loadSharedData();

    if (user && !user.member_id && members.length > 0) {
      await promptMemberLink();
    }

    Calendar.init();
    Todos.init();
    Members.init();
    Meals.init();
    Recipes.init();
    Shopping.init();
    Voice.init();
    switchView('calendar');
    refreshProposalBadge();
  }

  function showFamilyOnboarding() {
    document.getElementById('auth-screen').classList.add('hidden');
    document.getElementById('app-screen').classList.add('hidden');
    document.getElementById('family-screen').classList.remove('hidden');
    const errEl = document.getElementById('family-error');

    document.getElementById('family-create-form').onsubmit = async (e) => {
      e.preventDefault();
      errEl.textContent = '';
      const name = document.getElementById('family-name').value.trim();
      try {
        await API.post('/api/auth/family', { name });
        const user = await API.get('/api/auth/me');
        API.setUser(user);
        await showApp();
      } catch (err) { errEl.textContent = err.message; }
    };

    document.getElementById('family-join-form').onsubmit = async (e) => {
      e.preventDefault();
      errEl.textContent = '';
      const invite_code = document.getElementById('family-invite-code').value.trim();
      try {
        await API.post('/api/auth/family/join', { invite_code });
        const user = await API.get('/api/auth/me');
        API.setUser(user);
        await showApp();
      } catch (err) { errEl.textContent = err.message; }
    };
  }

  async function promptMemberLink() {
    return new Promise((resolve) => {
      const opts = members.map(m =>
        `<option value="${m.id}">${m.avatar_emoji} ${esc(m.name)}</option>`
      ).join('');
      const html = `<form>
        <p style="margin-bottom:1rem;color:var(--text-light)">Bitte waehle aus, welches Familienmitglied du bist. Das wird fuer Terminvorschlaege benoetigt.</p>
        <label>Ich bin...</label>
        <select name="member_id" required>${opts}</select>
        <p class="modal-error" style="color:var(--red);font-size:0.85rem;min-height:1em"></p>
        <div class="modal-footer">
          <button type="submit" class="btn-small btn-primary">Bestaetigen</button>
        </div>
      </form>`;
      openModal('Familienmitglied verknuepfen', html, async (fd) => {
        const memberId = parseInt(fd.get('member_id'));
        const updated = await API.patch('/api/auth/link-member', { member_id: memberId });
        API.setUser(updated);
        resolve();
      });
    });
  }

  async function refreshProposalBadge() {
    const badge = document.getElementById('proposal-badge');
    if (!badge) return;
    const user = API.getUser();
    if (!user || !user.member_id) {
      badge.classList.add('hidden');
      return;
    }
    try {
      const pending = await API.get('/api/proposals/pending');
      if (pending.length > 0) {
        badge.textContent = pending.length;
        badge.classList.remove('hidden');
      } else {
        badge.classList.add('hidden');
      }
    } catch {
      badge.classList.add('hidden');
    }
  }

  async function loadSharedData() {
    try {
      [categories, members] = await Promise.all([
        API.get('/api/categories/'),
        API.get('/api/family-members/'),
      ]);
    } catch {
      categories = [];
      members = [];
    }
  }

  /* ── Navigation ─────────────────────────────── */
  function initNav() {
    document.querySelectorAll('.nav-btn').forEach(btn => {
      btn.addEventListener('click', () => switchView(btn.dataset.view));
    });
    document.getElementById('logout-btn').addEventListener('click', () => {
      API.clearToken();
      location.reload();
    });
    const proposalBtn = document.getElementById('proposal-btn');
    if (proposalBtn) {
      proposalBtn.addEventListener('click', () => showPendingProposals());
    }
  }

  function switchView(name) {
    document.querySelectorAll('.view').forEach(v => v.classList.add('hidden'));
    document.getElementById(`view-${name}`).classList.remove('hidden');
    document.querySelectorAll('.nav-btn').forEach(b => b.classList.toggle('active', b.dataset.view === name));
    if (name === 'todos') Todos.refresh();
    if (name === 'members') Members.refresh();
    if (name === 'meals') Meals.loadWeek();
  }

  /* ── Pending Proposals View ─────────────────── */
  async function showPendingProposals() {
    try {
      const pending = await API.get('/api/proposals/pending');
      if (pending.length === 0) {
        openModal('Offene Terminvorschlaege', '<p style="color:var(--text-light);text-align:center;padding:1rem">Keine offenen Vorschlaege.</p>');
        return;
      }

      const items = pending.map(p => {
        const d = new Date(p.proposed_date).toLocaleString('de-DE', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
        return `<div style="padding:0.75rem;background:var(--bg);border-radius:var(--radius);margin-bottom:0.5rem">
          <div style="font-weight:600">${esc(p.todo_title)}</div>
          <div style="font-size:0.85rem;color:var(--text-light);margin:0.25rem 0">
            ${p.proposer.avatar_emoji} ${esc(p.proposer.name)} schlaegt vor: <strong>${d}</strong>
          </div>
          ${p.message ? `<div style="font-size:0.85rem;font-style:italic;margin-bottom:0.5rem">${esc(p.message)}</div>` : ''}
          <div style="display:flex;gap:0.5rem;margin-top:0.5rem">
            <button class="btn-small btn-primary" onclick="App.respondProposal(${p.id},'accepted')">Annehmen</button>
            <button class="btn-small btn-danger" onclick="App.respondProposal(${p.id},'rejected')">Ablehnen</button>
            <button class="btn-small" onclick="App.counterProposal(${p.id},${p.todo_id})">Gegenvorschlag</button>
          </div>
        </div>`;
      }).join('');

      openModal('Offene Terminvorschlaege', items);
    } catch (err) {
      alert(err.message);
    }
  }

  async function respondProposal(proposalId, response) {
    try {
      await API.post(`/api/proposals/${proposalId}/respond`, { response });
      closeModal();
      await refreshProposalBadge();
      showPendingProposals();
    } catch (err) { alert(err.message); }
  }

  async function counterProposal(proposalId, todoId) {
    const html = `<form>
      <label>Neuer Terminvorschlag</label>
      <input type="datetime-local" name="counter_date" required>
      <label>Nachricht (optional)</label>
      <textarea name="message" rows="2"></textarea>
      <p class="modal-error" style="color:var(--red);font-size:0.85rem;min-height:1em"></p>
      <div class="modal-footer">
        <button type="submit" class="btn-small btn-primary">Gegenvorschlag senden</button>
      </div>
    </form>`;

    openModal('Gegenvorschlag', html, async (fd) => {
      const counterDate = fd.get('counter_date');
      const message = fd.get('message') || null;
      await API.post(`/api/proposals/${proposalId}/respond`, {
        response: 'rejected',
        counter_date: new Date(counterDate).toISOString(),
        message,
      });
      await refreshProposalBadge();
    });
  }

  /* ── Modal ──────────────────────────────────── */
  function openModal(title, bodyHtml, onSubmit) {
    document.getElementById('modal-title').textContent = title;
    document.getElementById('modal-body').innerHTML = bodyHtml;
    const overlay = document.getElementById('modal-overlay');
    overlay.classList.remove('hidden');

    document.getElementById('modal-close').onclick = closeModal;
    overlay.onclick = (e) => { if (e.target === overlay) closeModal(); };

    if (onSubmit) {
      const form = document.getElementById('modal-body').querySelector('form');
      if (form) form.addEventListener('submit', async (e) => {
        e.preventDefault();
        try {
          await onSubmit(new FormData(form));
          closeModal();
        } catch (err) {
          const errEl = form.querySelector('.modal-error');
          if (errEl) errEl.textContent = err.message;
        }
      });
    }
    return closeModal;
  }

  function closeModal() {
    document.getElementById('modal-overlay').classList.add('hidden');
    document.getElementById('modal').classList.remove('modal-wide');
  }

  function openSecondaryModal(title, bodyHtml, onSubmit) {
    document.getElementById('modal-title-2').textContent = title;
    document.getElementById('modal-body-2').innerHTML = bodyHtml;
    const overlay = document.getElementById('modal-overlay-2');
    overlay.classList.remove('hidden');

    document.getElementById('modal-close-2').onclick = closeSecondaryModal;
    overlay.onclick = (e) => { if (e.target === overlay) closeSecondaryModal(); };

    if (onSubmit) {
      const form = document.getElementById('modal-body-2').querySelector('form');
      if (form) form.addEventListener('submit', async (e) => {
        e.preventDefault();
        try {
          await onSubmit(new FormData(form));
          closeSecondaryModal();
        } catch (err) {
          const errEl = form.querySelector('.modal-error');
          if (errEl) errEl.textContent = err.message;
        }
      });
    }
  }

  function closeSecondaryModal() {
    document.getElementById('modal-overlay-2').classList.add('hidden');
  }

  /* ── Helpers ────────────────────────────────── */
  function memberChipsHtml(selectedIds = []) {
    return `<div class="checkbox-group">${members.map(m =>
      `<span class="chip ${selectedIds.includes(m.id) ? 'selected' : ''}" data-id="${m.id}">${m.avatar_emoji} ${esc(m.name)}</span>`
    ).join('')}</div>`;
  }

  function categoryOptionsHtml(selectedId) {
    return `<option value="">Keine Kategorie</option>` +
      categories.map(c => `<option value="${c.id}" ${c.id === selectedId ? 'selected' : ''}>${c.icon} ${esc(c.name)}</option>`).join('');
  }

  function initChipSelection(container) {
    container.querySelectorAll('.chip').forEach(chip => {
      chip.addEventListener('click', () => chip.classList.toggle('selected'));
    });
  }

  function getSelectedChipIds(container) {
    return [...container.querySelectorAll('.chip.selected')].map(c => parseInt(c.dataset.id));
  }

  function formatTime(dtStr) {
    const d = new Date(dtStr);
    return d.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
  }

  function formatDate(dtStr) {
    return new Date(dtStr).toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit', year: 'numeric' });
  }

  function getCategoryColor(catId) {
    const cat = categories.find(c => c.id === catId);
    return cat ? cat.color : '#6B778C';
  }

  function formatDateISO(d) {
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }

  /* ── Theme ──────────────────────────────────── */
  const THEME_KEY = 'fk_theme';
  function initTheme() {
    const saved = localStorage.getItem(THEME_KEY);
    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    const dark = saved ? saved === 'dark' : prefersDark;
    applyTheme(dark);
    const btn = document.getElementById('theme-toggle');
    if (btn) btn.addEventListener('click', () => applyTheme(document.documentElement.dataset.theme !== 'dark'));
  }
  function applyTheme(dark) {
    document.documentElement.dataset.theme = dark ? 'dark' : 'light';
    localStorage.setItem(THEME_KEY, dark ? 'dark' : 'light');
    const btn = document.getElementById('theme-toggle');
    if (btn) btn.textContent = dark ? '\u2600' : '\u263E';
  }

  /* ── Init ───────────────────────────────────── */
  async function init() {
    initTheme();
    initAuth();
    initNav();
    if (API.getToken()) {
      try {
        const user = await API.get('/api/auth/me');
        API.setUser(user);
        await showApp();
      } catch {
        showAuth();
      }
    } else {
      showAuth();
    }
  }

  document.addEventListener('DOMContentLoaded', init);

  return {
    get categories() { return categories; },
    get members() { return members; },
    loadSharedData,
    openModal, closeModal, openSecondaryModal, closeSecondaryModal,
    DIFFICULTY_LABELS, DIFFICULTY_CLASS,
    memberChipsHtml, categoryOptionsHtml, initChipSelection, getSelectedChipIds,
    formatTime, formatDate, formatDateISO, getCategoryColor,
    switchView,
    refreshProposalBadge,
    respondProposal,
    counterProposal,
  };
})();

function esc(s) { if (!s) return ''; const t = document.createElement('span'); t.textContent = s; return t.innerHTML; }
