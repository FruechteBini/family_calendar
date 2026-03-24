/**
 * Calendar view: month grid, event display, event creation/editing.
 */
const Calendar = (() => {
  let currentDate = new Date();
  let events = [];
  let selectedDate = null;
  const MS_PER_DAY = 86_400_000;
  const toDateStr = App.formatDateISO;

  function init() {
    document.getElementById('cal-prev').addEventListener('click', () => navigate(-1));
    document.getElementById('cal-next').addEventListener('click', () => navigate(1));
    document.getElementById('cal-today').addEventListener('click', () => {
      currentDate = new Date();
      render();
    });
    document.getElementById('day-panel-close').addEventListener('click', closeDayPanel);
    document.getElementById('day-panel-add').addEventListener('click', () => openEventModal());
    render();
  }

  function navigate(delta) {
    currentDate.setMonth(currentDate.getMonth() + delta);
    render();
  }

  async function render() {
    const year = currentDate.getFullYear();
    const month = currentDate.getMonth();
    const monthNames = ['Januar','Februar','Maerz','April','Mai','Juni','Juli','August','September','Oktober','November','Dezember'];
    document.getElementById('cal-title').textContent = `${monthNames[month]} ${year}`;

    const firstDay = new Date(year, month, 1);
    const lastDay = new Date(year, month + 1, 0);
    const startOffset = (firstDay.getDay() + 6) % 7;
    const gridStart = new Date(firstDay);
    gridStart.setDate(gridStart.getDate() - startOffset);

    const gridEnd = new Date(lastDay);
    const endOffset = (7 - ((lastDay.getDay() + 6) % 7 + 1)) % 7;
    gridEnd.setDate(gridEnd.getDate() + endOffset);

    const from = gridStart.toISOString();
    const to = new Date(gridEnd.getTime() + MS_PER_DAY).toISOString();
    try {
      events = await API.get(`/api/events/?date_from=${from}&date_to=${to}`);
    } catch { events = []; }

    const container = document.getElementById('cal-days');
    container.innerHTML = '';
    const today = new Date();
    const d = new Date(gridStart);

    while (d <= gridEnd) {
      const cell = document.createElement('div');
      cell.className = 'cal-day';
      const dateStr = toDateStr(d);

      if (d.getMonth() !== month) cell.classList.add('other-month');
      if (dateStr === toDateStr(today)) cell.classList.add('today');
      if (selectedDate && dateStr === toDateStr(selectedDate)) cell.classList.add('selected');

      const dayEvents = getEventsForDate(d);
      const numEl = document.createElement('div');
      numEl.className = 'cal-day-num';
      numEl.textContent = d.getDate();
      cell.appendChild(numEl);

      const maxShow = 3;
      dayEvents.slice(0, maxShow).forEach(ev => {
        const tag = document.createElement('div');
        tag.className = 'cal-event';
        tag.style.background = ev.category ? ev.category.color : '#6B778C';
        tag.textContent = ev.all_day ? ev.title : `${App.formatTime(ev.start)} ${ev.title}`;
        cell.appendChild(tag);
      });
      if (dayEvents.length > maxShow) {
        const more = document.createElement('div');
        more.className = 'cal-day-more';
        more.textContent = `+${dayEvents.length - maxShow} mehr`;
        cell.appendChild(more);
      }

      const cellDate = new Date(d);
      cell.addEventListener('click', () => openDayPanel(cellDate));
      cell.addEventListener('dblclick', (e) => {
        e.preventDefault();
        selectedDate = cellDate;
        openEventModal();
      });
      container.appendChild(cell);
      d.setDate(d.getDate() + 1);
    }
  }

  function getEventsForDate(date) {
    const ds = toDateStr(date);
    return events.filter(ev => {
      const start = toDateStr(new Date(ev.start));
      const end = toDateStr(new Date(ev.end));
      return ds >= start && ds <= end;
    });
  }

  function openDayPanel(date) {
    selectedDate = date;
    const panel = document.getElementById('day-panel');
    panel.classList.remove('hidden');
    const options = { weekday: 'long', day: 'numeric', month: 'long', year: 'numeric' };
    document.getElementById('day-panel-title').textContent = date.toLocaleDateString('de-DE', options);

    const dayEvents = getEventsForDate(date);
    const container = document.getElementById('day-panel-events');
    if (dayEvents.length === 0) {
      container.innerHTML = '<p style="color:var(--text-light);font-size:0.9rem;padding:0.5rem 0">Keine Events an diesem Tag.</p>';
    } else {
      container.innerHTML = dayEvents.map(ev => `
        <div class="day-event-item">
          <div class="day-event-dot" style="background:${ev.category ? ev.category.color : '#6B778C'}"></div>
          <span class="day-event-time">${ev.all_day ? 'Ganztaegig' : App.formatTime(ev.start) + ' - ' + App.formatTime(ev.end)}</span>
          <span class="day-event-title">${esc(ev.title)}</span>
          <span class="day-event-members">${ev.members.map(m => m.avatar_emoji).join(' ')}</span>
          <div class="day-event-actions">
            <button class="btn-icon" onclick="Calendar.editEvent(${ev.id})" title="Bearbeiten">&#9998;</button>
            <button class="btn-icon" onclick="Calendar.deleteEvent(${ev.id})" title="Loeschen">&times;</button>
          </div>
        </div>
      `).join('');
    }
    render();
  }

  function closeDayPanel() {
    document.getElementById('day-panel').classList.add('hidden');
    selectedDate = null;
    render();
  }

  /* ── Time Dropdown Helpers ─────────────────── */
  function buildTimeOptions(selectedTime) {
    let opts = '';
    for (let h = 0; h < 24; h++) {
      for (let m = 0; m < 60; m += 15) {
        const val = `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
        const sel = val === selectedTime ? ' selected' : '';
        opts += `<option value="${val}"${sel}>${val}</option>`;
      }
    }
    return opts;
  }

  function nearestQuarter(timeStr) {
    const [h, m] = timeStr.split(':').map(Number);
    const rounded = Math.round(m / 15) * 15;
    if (rounded >= 60) return `${String(h + 1).padStart(2, '0')}:00`;
    return `${String(h).padStart(2, '0')}:${String(rounded).padStart(2, '0')}`;
  }

  /* ── Linked Todos Helpers ──────────────────── */
  let pendingTodos = [];

  function renderLinkedTodosHtml(existingTodos, isEdit) {
    const existing = (existingTodos || []).map(t => `
      <div class="linked-todo-item">
        <div class="linked-todo-status ${t.completed ? 'done' : ''}">${t.completed ? '&#10003;' : ''}</div>
        <span class="linked-todo-title ${t.completed ? 'done' : ''}">${esc(t.title)}</span>
        <span class="linked-todo-priority priority-badge priority-${t.priority}">${t.priority}</span>
      </div>
    `).join('');

    const pending = pendingTodos.map((t, i) => `
      <div class="linked-todo-item">
        <div class="linked-todo-status"></div>
        <span class="linked-todo-title">${esc(t.title)}</span>
        <span class="linked-todo-priority priority-badge priority-${t.priority}">${t.priority}</span>
        <button type="button" class="linked-todo-remove" data-pending-idx="${i}" title="Entfernen">&times;</button>
      </div>
    `).join('');

    const isEmpty = !existing && !pending;
    const emptyMsg = isEmpty ? '<div class="linked-todo-empty">Keine zugehoerigen Aufgaben.</div>' : '';

    return `
      <div class="linked-todos-section">
        <label>Zugehoerige Aufgaben</label>
        <div class="linked-todo-list" id="linked-todos-container">
          ${existing}${pending}${emptyMsg}
        </div>
        <button type="button" class="btn-small" id="add-linked-todo-btn" style="margin-top:0.4rem">+ Aufgabe hinzufuegen</button>
      </div>`;
  }

  function refreshLinkedTodosUI(existingTodos) {
    const container = document.getElementById('linked-todos-container');
    if (!container) return;

    const existing = (existingTodos || []).map(t => `
      <div class="linked-todo-item">
        <div class="linked-todo-status ${t.completed ? 'done' : ''}">${t.completed ? '&#10003;' : ''}</div>
        <span class="linked-todo-title ${t.completed ? 'done' : ''}">${esc(t.title)}</span>
        <span class="linked-todo-priority priority-badge priority-${t.priority}">${t.priority}</span>
      </div>
    `).join('');

    const pending = pendingTodos.map((t, i) => `
      <div class="linked-todo-item">
        <div class="linked-todo-status"></div>
        <span class="linked-todo-title">${esc(t.title)}</span>
        <span class="linked-todo-priority priority-badge priority-${t.priority}">${t.priority}</span>
        <button type="button" class="linked-todo-remove" data-pending-idx="${i}" title="Entfernen">&times;</button>
      </div>
    `).join('');

    const isEmpty = !existing && !pending;
    container.innerHTML = existing + pending + (isEmpty ? '<div class="linked-todo-empty">Keine zugehoerigen Aufgaben.</div>' : '');

    container.querySelectorAll('.linked-todo-remove').forEach(btn => {
      btn.addEventListener('click', () => {
        pendingTodos.splice(parseInt(btn.dataset.pendingIdx), 1);
        refreshLinkedTodosUI(existingTodos);
      });
    });
  }

  function openAddTodoPopup(existingTodos) {
    const html = `<form>
      <label>Titel</label>
      <input name="title" required placeholder="Aufgabe...">
      <label>Prioritaet</label>
      <select name="priority">
        <option value="medium">Mittel</option>
        <option value="high">Hoch</option>
        <option value="low">Niedrig</option>
      </select>
      <label>Mitglieder</label>
      ${App.memberChipsHtml([])}
      <p class="modal-error" style="color:var(--red);font-size:0.85rem;min-height:1em"></p>
      <div class="modal-footer">
        <button type="submit" class="btn-small btn-primary">Hinzufuegen</button>
      </div>
    </form>`;

    App.openSecondaryModal('Aufgabe fuer Event', html, async (fd) => {
      const memberChips = document.querySelectorAll('#modal-body-2 .chip.selected');
      const memberIds = [...memberChips].map(c => parseInt(c.dataset.id));
      pendingTodos.push({
        title: fd.get('title'),
        priority: fd.get('priority'),
        member_ids: memberIds,
      });
      refreshLinkedTodosUI(existingTodos);
    });

    App.initChipSelection(document.querySelector('#modal-body-2 .checkbox-group'));
  }

  /* ── Event Modal ────────────────────────────── */
  function openEventModal(event) {
    const isEdit = !!event;
    const title = isEdit ? 'Event bearbeiten' : 'Neues Event';
    pendingTodos = [];

    const dateDefault = selectedDate ? toDateStr(selectedDate) : toDateStr(new Date());
    const startDate = event ? toDateStr(new Date(event.start)) : dateDefault;
    const endDate = event ? toDateStr(new Date(event.end)) : dateDefault;
    const startTime = event ? nearestQuarter(toTimeStr(new Date(event.start))) : '09:00';
    const endTime = event ? nearestQuarter(toTimeStr(new Date(event.end))) : '10:00';
    const memberIds = event ? event.members.map(m => m.id) : [];
    const isAllDay = event ? event.all_day : false;
    const existingTodos = (isEdit && Array.isArray(event.todos)) ? event.todos : [];

    const linkedTodosHtml = renderLinkedTodosHtml(existingTodos, isEdit);

    const html = `<form>
      <label>Titel</label>
      <input name="title" value="${esc(event?.title || '')}" required>
      <label>Beschreibung</label>
      <textarea name="description">${esc(event?.description || '')}</textarea>

      <div class="event-allday">
        <input type="checkbox" name="all_day" id="event-allday-cb" ${isAllDay ? 'checked' : ''}>
        <label for="event-allday-cb">Ganztaegig</label>
      </div>

      <div class="event-datetime-row">
        <div>
          <label>Start</label>
          <div class="datetime-group" id="dt-start">
            <input type="date" name="start_date" value="${startDate}" required>
            <select name="start_time" class="dt-time">${buildTimeOptions(startTime)}</select>
          </div>
        </div>
        <div>
          <label>Ende</label>
          <div class="datetime-group" id="dt-end">
            <input type="date" name="end_date" value="${endDate}" required>
            <select name="end_time" class="dt-time">${buildTimeOptions(endTime)}</select>
          </div>
        </div>
      </div>

      <label>Kategorie</label>
      <select name="category_id">${App.categoryOptionsHtml(event?.category?.id)}</select>
      <label>Mitglieder</label>
      ${App.memberChipsHtml(memberIds)}

      ${linkedTodosHtml}

      <p class="modal-error" style="color:var(--red);font-size:0.85rem;min-height:1em"></p>
      <div class="modal-footer">
        ${isEdit ? '<button type="button" class="btn-small btn-danger" id="modal-delete-event">Loeschen</button>' : ''}
        <button type="submit" class="btn-small btn-primary">${isEdit ? 'Speichern' : 'Erstellen'}</button>
      </div>
    </form>`;

    App.openModal(title, html, async (fd) => {
      const allDay = fd.has('all_day');
      const sDate = fd.get('start_date');
      const eDate = fd.get('end_date');
      const sTime = allDay ? '00:00' : fd.get('start_time');
      const eTime = allDay ? '23:59' : fd.get('end_time');
      const body = {
        title: fd.get('title'),
        description: fd.get('description') || null,
        all_day: allDay,
        start: new Date(`${sDate}T${sTime}`).toISOString(),
        end: new Date(`${eDate}T${eTime}`).toISOString(),
        category_id: fd.get('category_id') ? parseInt(fd.get('category_id')) : null,
        member_ids: App.getSelectedChipIds(document.querySelector('#modal-body .checkbox-group')),
      };

      let savedEvent;
      if (isEdit) {
        savedEvent = await API.put(`/api/events/${event.id}`, body);
      } else {
        savedEvent = await API.post('/api/events/', body);
      }

      for (const t of pendingTodos) {
        await API.post('/api/todos/', {
          title: t.title,
          priority: t.priority,
          event_id: savedEvent.id,
          member_ids: t.member_ids || [],
        });
      }

      await render();
      if (selectedDate) openDayPanel(selectedDate);
    });

    App.initChipSelection(document.querySelector('#modal-body .checkbox-group'));
    setupAllDayToggle();

    document.getElementById('add-linked-todo-btn')?.addEventListener('click', () => {
      openAddTodoPopup(existingTodos);
    });

    container_removeBtns(existingTodos);

    if (isEdit) {
      document.getElementById('modal-delete-event')?.addEventListener('click', async () => {
        if (confirm('Event wirklich loeschen?')) {
          try {
            await API.delete(`/api/events/${event.id}`);
            App.closeModal();
            await render();
            if (selectedDate) openDayPanel(selectedDate);
          } catch (err) { alert(err.message); }
        }
      });
    }
  }

  function container_removeBtns(existingTodos) {
    const container = document.getElementById('linked-todos-container');
    if (!container) return;
    container.querySelectorAll('.linked-todo-remove').forEach(btn => {
      btn.addEventListener('click', () => {
        pendingTodos.splice(parseInt(btn.dataset.pendingIdx), 1);
        refreshLinkedTodosUI(existingTodos);
      });
    });
  }

  function setupAllDayToggle() {
    const cb = document.getElementById('event-allday-cb');
    if (!cb) return;
    const timeEls = document.querySelectorAll('#modal-body .dt-time');
    const toggle = () => timeEls.forEach(el => el.style.display = cb.checked ? 'none' : '');
    cb.addEventListener('change', toggle);
    toggle();
  }

  async function editEvent(id) {
    try {
      const event = await API.get(`/api/events/${id}`);
      openEventModal(event);
    } catch (err) { alert(err.message); }
  }

  async function deleteEvent(id) {
    if (confirm('Event wirklich loeschen?')) {
      try {
        await API.delete(`/api/events/${id}`);
        await render();
        if (selectedDate) openDayPanel(selectedDate);
      } catch (err) { alert(err.message); }
    }
  }

  /* ── Helpers ────────────────────────────────── */
  function toInputDateTime(d) {
    return `${toDateStr(d)}T${String(d.getHours()).padStart(2,'0')}:${String(d.getMinutes()).padStart(2,'0')}`;
  }

  function toTimeStr(d) {
    return `${String(d.getHours()).padStart(2, '0')}:${String(d.getMinutes()).padStart(2, '0')}`;
  }

  return { init, render, editEvent, deleteEvent };
})();
