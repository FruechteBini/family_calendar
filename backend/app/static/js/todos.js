/**
 * Todo list view with sub-todos, assignment types, and proposal support.
 */
const Todos = (() => {
  let todos = [];
  let allEvents = [];

  function init() {
    document.getElementById('todo-quick-add').addEventListener('click', quickAdd);
    document.getElementById('todo-quick-input').addEventListener('keydown', (e) => {
      if (e.key === 'Enter') quickAdd();
    });
    document.getElementById('todo-filter-priority').addEventListener('change', refresh);
    document.getElementById('todo-filter-member').addEventListener('change', refresh);
    document.getElementById('todo-filter-done').addEventListener('change', refresh);
    populateMemberFilter();
  }

  function populateMemberFilter() {
    const sel = document.getElementById('todo-filter-member');
    sel.innerHTML = '<option value="">Alle Mitglieder</option>' +
      App.members.map(m => `<option value="${m.id}">${m.avatar_emoji} ${esc(m.name)}</option>`).join('');
  }

  async function refresh() {
    const params = new URLSearchParams();
    const priority = document.getElementById('todo-filter-priority').value;
    const memberId = document.getElementById('todo-filter-member').value;
    const showDone = document.getElementById('todo-filter-done').checked;

    if (priority) params.set('priority', priority);
    if (memberId) params.set('member_id', memberId);
    if (!showDone) params.set('completed', 'false');

    try {
      [todos, allEvents] = await Promise.all([
        API.get(`/api/todos/?${params}`),
        API.get('/api/events/'),
      ]);
    } catch { todos = []; allEvents = []; }

    renderList();
  }

  function renderList() {
    const container = document.getElementById('todo-list');
    if (todos.length === 0) {
      container.innerHTML = '<p style="text-align:center;color:var(--text-light);padding:2rem">Keine Aufgaben gefunden.</p>';
      return;
    }
    container.innerHTML = todos.map(todo => renderTodoItem(todo)).join('');
  }

  function renderTodoItem(todo) {
    const priClass = `priority-${todo.priority}`;
    const memberEmojis = todo.members.map(m => m.avatar_emoji).join(' ');
    const dueStr = todo.due_date ? App.formatDate(todo.due_date + 'T00:00:00') : '';
    const isOverdue = todo.due_date && !todo.completed && new Date(todo.due_date) < new Date(new Date().toDateString());
    const linkedEvent = todo.event_id ? allEvents.find(ev => ev.id === todo.event_id) : null;
    const subs = todo.subtodos || [];
    const doneCount = subs.filter(s => s.completed).length;
    const subCountLabel = subs.length ? `<span style="color:var(--text-light);font-size:0.75rem">${doneCount}/${subs.length}</span>` : '';
    const multiLabel = todo.requires_multiple ? '<span class="multi-badge">Mehrere</span>' : '';

    return `
      <div class="todo-item ${todo.completed ? 'completed' : ''}">
        <div class="todo-check ${todo.completed ? 'checked' : ''}" onclick="Todos.toggle(${todo.id})">
          ${todo.completed ? '&#10003;' : ''}
        </div>
        <div class="todo-body">
          <div class="todo-title">${esc(todo.title)} ${subCountLabel} ${multiLabel}</div>
          <div class="todo-meta">
            <span class="priority-badge ${priClass}">${todo.priority}</span>
            ${todo.category ? `<span>${todo.category.icon} ${esc(todo.category.name)}</span>` : ''}
            ${memberEmojis ? `<span>${memberEmojis}</span>` : ''}
            ${dueStr ? `<span style="${isOverdue ? 'color:var(--red);font-weight:600' : ''}">${dueStr}</span>` : ''}
            ${linkedEvent ? `<span style="color:var(--blue)">&#128197; ${esc(linkedEvent.title)}</span>` : ''}
          </div>
          ${renderSubtodos(todo.id, subs)}
        </div>
        <div class="todo-actions">
          ${todo.requires_multiple ? `<button class="btn-icon" onclick="Todos.proposeDate(${todo.id})" title="Terminvorschlag">&#128197;</button>` : ''}
          <button class="btn-icon" onclick="Todos.addSub(${todo.id})" title="Sub-Todo hinzufuegen">+</button>
          <button class="btn-icon" onclick="Todos.edit(${todo.id})" title="Bearbeiten">&#9998;</button>
          <button class="btn-icon" onclick="Todos.remove(${todo.id})" title="Loeschen">&times;</button>
        </div>
      </div>`;
  }

  function renderSubtodos(parentId, subs) {
    if (!subs.length) return '';
    const items = subs.map(s => `
      <div class="subtodo-item ${s.completed ? 'completed' : ''}">
        <div class="todo-check ${s.completed ? 'checked' : ''}" onclick="Todos.toggle(${s.id})" style="width:16px;height:16px;font-size:0.6rem">
          ${s.completed ? '&#10003;' : ''}
        </div>
        <span class="subtodo-title">${esc(s.title)}</span>
        <button class="btn-icon" onclick="Todos.remove(${s.id})" style="font-size:0.85rem" title="Loeschen">&times;</button>
      </div>
    `).join('');
    return `<div class="subtodo-list">${items}</div>`;
  }

  async function quickAdd() {
    const input = document.getElementById('todo-quick-input');
    const title = input.value.trim();
    if (!title) return;
    const priority = document.getElementById('todo-quick-priority').value;
    try {
      await API.post('/api/todos/', { title, priority });
      input.value = '';
      await refresh();
    } catch (err) { alert(err.message); }
  }

  function addSub(parentId) {
    const html = `<form>
      <label>Titel</label>
      <input name="title" required placeholder="Sub-Todo...">
      <p class="modal-error" style="color:var(--red);font-size:0.85rem;min-height:1em"></p>
      <div class="modal-footer">
        <button type="submit" class="btn-small btn-primary">Hinzufuegen</button>
      </div>
    </form>`;
    App.openSecondaryModal('Sub-Todo erstellen', html, async (fd) => {
      const title = fd.get('title').trim();
      if (!title) return;
      await API.post('/api/todos/', { title, parent_id: parentId });
      await refresh();
    });
  }

  async function toggle(id) {
    try {
      await API.patch(`/api/todos/${id}/complete`);
      await refresh();
    } catch (err) { alert(err.message); }
  }

  async function remove(id) {
    if (confirm('Wirklich loeschen?')) {
      try {
        await API.delete(`/api/todos/${id}`);
        await refresh();
      } catch (err) { alert(err.message); }
    }
  }

  function eventOptionsHtml(selectedId) {
    return `<option value="">Kein Event verknuepft</option>` +
      allEvents.map(ev => {
        const d = App.formatDate(ev.start);
        return `<option value="${ev.id}" ${ev.id === selectedId ? 'selected' : ''}>${d} – ${esc(ev.title)}</option>`;
      }).join('');
  }

  async function edit(id) {
    let todo;
    try { todo = await API.get(`/api/todos/${id}`); } catch (err) { alert(err.message); return; }
    if (!allEvents.length) {
      try { allEvents = await API.get('/api/events/'); } catch { allEvents = []; }
    }
    const memberIds = todo.members.map(m => m.id);

    let proposalSection = '';
    if (todo.requires_multiple) {
      try {
        const proposals = await API.get(`/api/todos/${id}/proposals`);
        proposalSection = renderProposalTimeline(proposals);
      } catch { proposalSection = ''; }
    }

    const html = `<form>
      <label>Titel</label>
      <input name="title" value="${esc(todo.title)}" required>
      <label>Beschreibung</label>
      <textarea name="description">${esc(todo.description || '')}</textarea>
      <label>Prioritaet</label>
      <select name="priority">
        <option value="low" ${todo.priority==='low'?'selected':''}>Niedrig</option>
        <option value="medium" ${todo.priority==='medium'?'selected':''}>Mittel</option>
        <option value="high" ${todo.priority==='high'?'selected':''}>Hoch</option>
      </select>
      <label>Faelligkeitsdatum</label>
      <input type="date" name="due_date" value="${todo.due_date || ''}">
      <label>Kategorie</label>
      <select name="category_id">${App.categoryOptionsHtml(todo.category?.id)}</select>
      <label>Verknuepftes Event</label>
      <select name="event_id">${eventOptionsHtml(todo.event_id)}</select>
      <label style="display:flex;align-items:center;gap:0.5rem;margin-top:1rem">
        <input type="checkbox" name="requires_multiple" ${todo.requires_multiple ? 'checked' : ''} style="width:auto">
        Mehrere Personen benoetigt
      </label>
      <label>Mitglieder</label>
      ${App.memberChipsHtml(memberIds)}
      ${proposalSection}
      <p class="modal-error" style="color:var(--red);font-size:0.85rem;min-height:1em"></p>
      <div class="modal-footer">
        <button type="button" class="btn-small btn-danger" id="modal-delete-todo">Loeschen</button>
        <button type="submit" class="btn-small btn-primary">Speichern</button>
      </div>
    </form>`;

    App.openModal('Aufgabe bearbeiten', html, async (fd) => {
      const body = {
        title: fd.get('title'),
        description: fd.get('description') || null,
        priority: fd.get('priority'),
        due_date: fd.get('due_date') || null,
        category_id: fd.get('category_id') ? parseInt(fd.get('category_id')) : null,
        event_id: fd.get('event_id') ? parseInt(fd.get('event_id')) : null,
        requires_multiple: !!fd.get('requires_multiple'),
        member_ids: App.getSelectedChipIds(document.querySelector('#modal-body .checkbox-group')),
      };
      await API.put(`/api/todos/${todo.id}`, body);
      await refresh();
    });

    App.initChipSelection(document.querySelector('#modal-body .checkbox-group'));

    document.getElementById('modal-delete-todo')?.addEventListener('click', async () => {
      if (confirm('Aufgabe wirklich loeschen?')) {
        try {
          await API.delete(`/api/todos/${todo.id}`);
          App.closeModal();
          await refresh();
        } catch (err) { alert(err.message); }
      }
    });
  }

  function renderProposalTimeline(proposals) {
    if (!proposals || proposals.length === 0) {
      return `<div class="proposal-section">
        <label style="margin-top:1rem">Terminvorschlaege</label>
        <p style="color:var(--text-light);font-size:0.85rem">Noch keine Vorschlaege.</p>
      </div>`;
    }

    const items = proposals.map(p => {
      const d = new Date(p.proposed_date).toLocaleString('de-DE', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
      const statusBadge = p.status === 'accepted'
        ? '<span class="proposal-status-accepted">Angenommen</span>'
        : p.status === 'rejected'
          ? '<span class="proposal-status-rejected">Abgelehnt</span>'
          : p.status === 'superseded'
            ? '<span class="proposal-status-superseded">Ersetzt</span>'
            : '<span class="proposal-status-pending">Offen</span>';

      const responses = (p.responses || []).map(r =>
        `<div style="font-size:0.8rem;margin-left:1rem;color:var(--text-light)">
          ${r.member.avatar_emoji} ${esc(r.member.name)}: <strong>${r.response === 'accepted' ? 'Angenommen' : 'Abgelehnt'}</strong>
          ${r.message ? ` – ${esc(r.message)}` : ''}
        </div>`
      ).join('');

      return `<div class="proposal-item">
        <div style="display:flex;justify-content:space-between;align-items:center">
          <span>${p.proposer.avatar_emoji} ${esc(p.proposer.name)}: <strong>${d}</strong></span>
          ${statusBadge}
        </div>
        ${p.message ? `<div style="font-size:0.85rem;font-style:italic;color:var(--text-light)">${esc(p.message)}</div>` : ''}
        ${responses}
      </div>`;
    }).join('');

    return `<div class="proposal-section">
      <label style="margin-top:1rem">Terminvorschlaege</label>
      ${items}
    </div>`;
  }

  async function proposeDate(todoId) {
    const html = `<form>
      <label>Vorgeschlagener Termin</label>
      <input type="datetime-local" name="proposed_date" required>
      <label>Nachricht (optional)</label>
      <textarea name="message" rows="2"></textarea>
      <p class="modal-error" style="color:var(--red);font-size:0.85rem;min-height:1em"></p>
      <div class="modal-footer">
        <button type="submit" class="btn-small btn-primary">Vorschlag senden</button>
      </div>
    </form>`;

    App.openModal('Terminvorschlag', html, async (fd) => {
      const proposedDate = fd.get('proposed_date');
      const message = fd.get('message') || null;
      await API.post(`/api/todos/${todoId}/proposals`, {
        proposed_date: new Date(proposedDate).toISOString(),
        message,
      });
      await refresh();
      App.refreshProposalBadge();
    });
  }

  return { init, refresh, toggle, edit, remove, addSub, proposeDate };
})();
