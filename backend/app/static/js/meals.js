/**
 * Meals module: week plan grid, slot assignment, recipe search, mark-as-cooked,
 * AI meal planning with preview/confirm/undo workflow.
 */
const Meals = (() => {
  let currentWeekStart = null;
  let weekData = null;
  let allRecipes = [];
  let cookingHistory = [];
  let lastAiMealIds = null;
  let lastAiUndoTimeout = null;

  const SLOT_LABELS = { lunch: 'Mittag', dinner: 'Abend' };
  const DAY_ABBR = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  const DAY_FULL = ['Montag', 'Dienstag', 'Mittwoch', 'Donnerstag', 'Freitag', 'Samstag', 'Sonntag'];
  const LONG_AGO_DAYS = 28;
  const UNDO_TIMEOUT_MS = 60_000;
  const MS_PER_DAY = 86_400_000;

  function init() {
    document.getElementById('week-prev').addEventListener('click', () => navigate(-7));
    document.getElementById('week-next').addEventListener('click', () => navigate(7));
    document.getElementById('week-today').addEventListener('click', () => { currentWeekStart = null; loadWeek(); });
    document.getElementById('generate-shopping-btn').addEventListener('click', generateShoppingList);
    document.getElementById('ai-meal-plan-btn').addEventListener('click', openAiMealPlanDialog);

    document.querySelectorAll('.meals-tab').forEach(tab => {
      tab.addEventListener('click', () => {
        document.querySelectorAll('.meals-tab').forEach(t => t.classList.remove('active'));
        tab.classList.add('active');
        document.querySelectorAll('.meals-subtab').forEach(s => s.classList.add('hidden'));
        document.getElementById(`subtab-${tab.dataset.subtab}`).classList.remove('hidden');
        if (tab.dataset.subtab === 'recipes') Recipes.refresh();
        if (tab.dataset.subtab === 'shopping') Shopping.refresh();
        if (tab.dataset.subtab === 'pantry') Pantry.refresh();
      });
    });
  }

  function navigate(days) {
    if (!currentWeekStart) currentWeekStart = mondayOf(new Date());
    currentWeekStart = addDays(currentWeekStart, days);
    loadWeek();
  }

  async function loadWeek() {
    const param = currentWeekStart ? `?week=${App.formatDateISO(currentWeekStart)}` : '';
    try {
      [weekData, allRecipes, cookingHistory] = await Promise.all([
        API.get(`/api/meals/plan${param}`),
        API.get('/api/recipes/?sort_by=title&order=asc'),
        API.get('/api/meals/history?limit=10'),
      ]);
    } catch (err) {
      weekData = null;
      allRecipes = [];
      cookingHistory = [];
    }
    render();
  }

  function render() {
    if (!weekData) return;
    const title = document.getElementById('week-title');
    const ws = new Date(weekData.week_start + 'T00:00:00');
    const we = addDays(ws, 6);
    title.textContent = `${formatDateDE(ws)} – ${formatDateDE(we)}`;
    currentWeekStart = ws;

    const grid = document.getElementById('week-grid');
    const now = new Date();
    const todayStr = App.formatDateISO(now);

    let html = '';

    if (lastAiMealIds) {
      html += `<div class="ai-undo-bar">
        <span>&#10024; KI-Plan erstellt (${lastAiMealIds.length} Mahlzeiten)</span>
        <button class="btn-small btn-undo" onclick="Meals.undoAiPlan()">Rueckgaengig machen</button>
        <button class="btn-icon ai-undo-dismiss" onclick="Meals.dismissUndo()">&times;</button>
      </div>`;
    }

    html += '<div class="week-header-row">';
    html += '<div class="week-slot-label"></div>';
    for (const day of weekData.days) {
      const isToday = day.date === todayStr;
      html += `<div class="week-day-header ${isToday ? 'today' : ''}">${day.weekday}<br><span class="week-day-date">${formatDateDE(new Date(day.date + 'T00:00:00'))}</span></div>`;
    }
    html += '</div>';

    for (const slotKey of ['lunch', 'dinner']) {
      html += '<div class="week-row">';
      html += `<div class="week-slot-label">${SLOT_LABELS[slotKey]}</div>`;
      for (const day of weekData.days) {
        const meal = day[slotKey];
        const isToday = day.date === todayStr;
        html += renderSlotCell(day.date, slotKey, meal, isToday);
      }
      html += '</div>';
    }
    grid.innerHTML = html;
    renderCookingHistory();
    _initDropTargets();
  }

  function renderCookingHistory() {
    let container = document.getElementById('cooking-history');
    if (!container) {
      container = document.createElement('div');
      container.id = 'cooking-history';
      document.getElementById('week-grid').after(container);
    }

    if (!cookingHistory || cookingHistory.length === 0) {
      container.innerHTML = '';
      return;
    }

    // Deduplicate: show each recipe only once (most recent)
    const seen = new Set();
    const unique = [];
    for (const entry of cookingHistory) {
      if (!seen.has(entry.recipe_id)) {
        seen.add(entry.recipe_id);
        unique.push(entry);
      }
    }

    let html = '<div class="history-header"><h3>Koch-Verlauf</h3><span class="history-hint">Zum Einplanen in den Wochenplan ziehen</span></div>';
    html += '<div class="history-cards">';
    for (const entry of unique) {
      const dateStr = new Date(entry.cooked_at).toLocaleDateString('de-DE', { day: 'numeric', month: 'short' });
      const ratingStr = entry.rating ? '&#9733;'.repeat(entry.rating) : '';
      const diffClass = App.DIFFICULTY_CLASS[entry.recipe_difficulty] || '';
      const diffLabel = App.DIFFICULTY_LABELS[entry.recipe_difficulty] || '';

      html += `<div class="history-card" draggable="true"
        data-recipe-id="${entry.recipe_id}" data-recipe-title="${esc(entry.recipe_title)}">
        <div class="history-card-title">${esc(entry.recipe_title)}</div>
        <div class="history-card-meta">
          ${diffLabel ? `<span class="diff-badge ${diffClass}">${diffLabel}</span>` : ''}
          <span class="history-card-date">${dateStr}</span>
          ${ratingStr ? `<span class="history-card-rating">${ratingStr}</span>` : ''}
        </div>
      </div>`;
    }
    html += '</div>';
    container.innerHTML = html;

    // Init drag on history cards
    container.querySelectorAll('.history-card').forEach(card => {
      card.addEventListener('dragstart', (e) => {
        e.dataTransfer.setData('application/recipe-id', card.dataset.recipeId);
        e.dataTransfer.setData('text/plain', card.dataset.recipeTitle);
        e.dataTransfer.effectAllowed = 'copy';
        card.classList.add('dragging');
      });
      card.addEventListener('dragend', () => {
        card.classList.remove('dragging');
        document.querySelectorAll('.week-slot.drag-over').forEach(el => el.classList.remove('drag-over'));
      });
    });
  }

  function _initDropTargets() {
    document.querySelectorAll('.week-slot.empty').forEach(slot => {
      slot.addEventListener('dragover', (e) => {
        if (e.dataTransfer.types.includes('application/recipe-id')) {
          e.preventDefault();
          e.dataTransfer.dropEffect = 'copy';
          slot.classList.add('drag-over');
        }
      });
      slot.addEventListener('dragleave', () => {
        slot.classList.remove('drag-over');
      });
      slot.addEventListener('drop', async (e) => {
        e.preventDefault();
        slot.classList.remove('drag-over');
        const recipeId = e.dataTransfer.getData('application/recipe-id');
        if (!recipeId) return;

        const dateStr = slot.dataset.date;
        const slotKey = slot.dataset.slot;
        try {
          await API.put(`/api/meals/plan/${dateStr}/${slotKey}`, {
            recipe_id: parseInt(recipeId),
            servings_planned: 4,
          });
          await loadWeek();
        } catch (err) { alert(err.message); }
      });
    });
  }

  function renderSlotCell(dateStr, slot, meal, isToday) {
    if (!meal) {
      return `<div class="week-slot empty ${isToday ? 'today' : ''}" data-date="${dateStr}" data-slot="${slot}" onclick="Meals.assignSlot('${dateStr}','${slot}')">
        <span class="slot-placeholder">+ Rezept</span>
      </div>`;
    }

    const r = meal.recipe;
    const diffBadge = `<span class="diff-badge ${App.DIFFICULTY_CLASS[r.difficulty] || ''}">${App.DIFFICULTY_LABELS[r.difficulty] || r.difficulty}</span>`;
    const timeStr = formatPrepTime(r.prep_time_active_minutes, r.prep_time_passive_minutes);
    const longAgo = isLongAgo(r.last_cooked_at);

    return `<div class="week-slot filled ${isToday ? 'today' : ''}" onclick="Meals.editSlot('${dateStr}','${slot}')">
      <div class="slot-title">${esc(r.title)}</div>
      <div class="slot-meta">
        ${diffBadge}
        ${timeStr ? `<span class="slot-time">${timeStr}</span>` : ''}
        <span class="slot-servings">${meal.servings_planned}P</span>
      </div>
      ${longAgo ? '<div class="slot-long-ago">Schon lange nicht mehr!</div>' : ''}
      <div class="slot-actions">
        <button class="btn-icon" onclick="event.stopPropagation();Meals.markCooked('${dateStr}','${slot}')" title="Als gekocht markieren">&#10003;</button>
        <button class="btn-icon" onclick="event.stopPropagation();Meals.clearSlot('${dateStr}','${slot}')" title="Slot leeren">&times;</button>
      </div>
    </div>`;
  }

  function isLongAgo(lastCookedAt) {
    if (!lastCookedAt) return true;
    const daysSinceCooked = (Date.now() - new Date(lastCookedAt).getTime()) / MS_PER_DAY;
    return daysSinceCooked > LONG_AGO_DAYS;
  }

  function formatPrepTime(active, passive) {
    const parts = [];
    if (active) parts.push(`${active}' aktiv`);
    if (passive) parts.push(`${passive}' passiv`);
    return parts.join(' / ');
  }

  async function assignSlot(dateStr, slot) {
    if (!allRecipes.length) {
      try { allRecipes = await API.get('/api/recipes/?sort_by=title&order=asc'); } catch { allRecipes = []; }
    }

    const recipeOpts = allRecipes.map(r => {
      const longAgo = isLongAgo(r.last_cooked_at);
      return `<option value="${r.id}" ${longAgo ? 'style="color:var(--orange)"' : ''}>${esc(r.title)}${longAgo ? ' ★' : ''}</option>`;
    }).join('');

    const html = `<form>
      <label>Rezept auswaehlen</label>
      <select name="recipe_id">
        <option value="">-- Rezept waehlen --</option>
        ${recipeOpts}
      </select>
      <div style="margin:0.5rem 0;font-size:0.85rem;color:var(--text-light)">
        Kein passendes Rezept? <a href="#" id="modal-new-recipe-link" style="color:var(--primary)">Neues Rezept anlegen</a>
      </div>
      <label>Oder Schnelleingabe (nur Name)</label>
      <input name="new_title" placeholder="Neuer Rezeptname (optional)">
      <label>Portionen</label>
      <input type="number" name="servings_planned" value="4" min="1" max="20" required>
      <p class="modal-error" style="color:var(--red);font-size:0.85rem;min-height:1em"></p>
      <div class="modal-footer">
        <button type="submit" class="btn-small btn-primary">Zuweisen</button>
      </div>
    </form>`;

    App.openModal(`${SLOT_LABELS[slot]} – ${formatDateDE(new Date(dateStr + 'T00:00:00'))}`, html, async (fd) => {
      let recipeId = fd.get('recipe_id') ? parseInt(fd.get('recipe_id')) : null;
      const newTitle = fd.get('new_title')?.trim();
      const servings = parseInt(fd.get('servings_planned')) || 4;

      if (!recipeId && newTitle) {
        const newRecipe = await API.post('/api/recipes/', { title: newTitle, servings });
        recipeId = newRecipe.id;
      }
      if (!recipeId) throw new Error('Bitte ein Rezept auswaehlen oder einen Namen eingeben');

      await API.put(`/api/meals/plan/${dateStr}/${slot}`, { recipe_id: recipeId, servings_planned: servings });
      await loadWeek();
    });

    const link = document.getElementById('modal-new-recipe-link');
    if (link) {
      link.addEventListener('click', (e) => {
        e.preventDefault();
        App.closeModal();
        Recipes.openRecipeForm();
      });
    }
  }

  async function clearSlot(dateStr, slot) {
    if (confirm('Slot wirklich leeren?')) {
      try {
        await API.delete(`/api/meals/plan/${dateStr}/${slot}`);
        await loadWeek();
      } catch (err) { alert(err.message); }
    }
  }

  async function markCooked(dateStr, slot) {
    const html = `<form>
      <label>Bewertung (optional, 1-5)</label>
      <input type="number" name="rating" min="1" max="5" placeholder="1-5">
      <label>Notizen (optional)</label>
      <textarea name="notes" rows="2"></textarea>
      <p class="modal-error" style="color:var(--red);font-size:0.85rem;min-height:1em"></p>
      <div class="modal-footer">
        <button type="submit" class="btn-small btn-primary">Als gekocht markieren</button>
      </div>
    </form>`;

    App.openModal('Gekocht!', html, async (fd) => {
      const body = {};
      const rating = fd.get('rating');
      const notes = fd.get('notes');
      if (rating) body.rating = parseInt(rating);
      if (notes) body.notes = notes;
      const result = await API.patch(`/api/meals/plan/${dateStr}/${slot}/done`, Object.keys(body).length ? body : null);
      await loadWeek();
      if (result && result.pantry_deductions && result.pantry_deductions.length > 0) {
        const lines = result.pantry_deductions.map(d =>
          `${d.name}: ${d.old_amount} \u2192 ${d.new_amount}${d.depleted ? ' (aufgebraucht)' : ''}`
        );
        _showPantryDeductionToast(lines);
      }
    });
  }

  /* ── AI Meal Plan: Multi-Step Dialog ────────────────── */

  function _openAiModal(titleText) {
    const modal = document.getElementById('modal');
    const overlay = document.getElementById('modal-overlay');

    modal.classList.add('modal-wide');
    document.getElementById('modal-title').textContent = titleText;
    document.getElementById('modal-body').innerHTML = '<div class="ai-loading"><div class="spinner"></div><p>Lade Rezeptdaten...</p></div>';
    overlay.classList.remove('hidden');

    const closeM = () => {
      overlay.classList.add('hidden');
      modal.classList.remove('modal-wide');
    };
    document.getElementById('modal-close').onclick = closeM;
    overlay.onclick = (e) => { if (e.target === overlay) closeM(); };
    return closeM;
  }

  async function openAiMealPlanDialog() {
    if (!weekData) return;

    const modalBody = document.getElementById('modal-body');
    const closeM = _openAiModal('KI-Essensplan erstellen');

    let info;
    try {
      info = await API.get(`/api/ai/available-recipes?week_start=${weekData.week_start}`);
    } catch (err) {
      modalBody.innerHTML = `<div class="ai-error-state"><p>${esc(err.message)}</p>
        <div class="modal-footer"><button class="btn-small" onclick="document.getElementById('modal-overlay').classList.add('hidden')">Schliessen</button></div></div>`;
      return;
    }

    _showConfigStep(info, closeM);
  }

  function _showConfigStep(info, closeM) {
    const modalBody = document.getElementById('modal-body');
    document.getElementById('modal-title').textContent = 'KI-Essensplan erstellen';

    const ws = new Date(weekData.week_start + 'T00:00:00');
    const we = addDays(ws, 6);
    const weekLabel = `${formatDateDE(ws)} – ${formatDateDE(we)}`;
    const filledSet = new Set(info.filled_slots.map(s => `${s.date}_${s.slot}`));

    const days = [];
    for (let i = 0; i < 7; i++) {
      const d = addDays(ws, i);
      days.push({ date: App.formatDateISO(d), abbr: DAY_ABBR[i], de: formatDateDE(d) });
    }

    let slotGrid = '<div class="ai-slot-grid">';
    slotGrid += '<div class="ai-slot-cell ai-slot-corner"></div>';
    for (const d of days) {
      slotGrid += `<div class="ai-slot-cell ai-slot-day-hdr">${d.abbr}<br><span class="ai-slot-date">${d.de}</span></div>`;
    }
    for (const slotKey of ['lunch', 'dinner']) {
      slotGrid += `<div class="ai-slot-cell ai-slot-label">${SLOT_LABELS[slotKey]}</div>`;
      for (const d of days) {
        const key = `${d.date}_${slotKey}`;
        if (filledSet.has(key)) {
          const f = info.filled_slots.find(s => `${s.date}_${s.slot}` === key);
          slotGrid += `<div class="ai-slot-cell ai-slot-filled" title="${esc(f?.recipe_title || 'Belegt')}">
            <span class="ai-slot-filled-text">${esc(f?.recipe_title || '–')}</span></div>`;
        } else {
          slotGrid += `<div class="ai-slot-cell ai-slot-empty">
            <input type="checkbox" name="slot" value="${key}" checked class="ai-slot-cb"></div>`;
        }
      }
    }
    slotGrid += '</div>';

    let cookidooHtml = '';
    if (info.cookidoo_available) {
      cookidooHtml = `<label class="ai-cookidoo-toggle">
        <input type="checkbox" name="include_cookidoo"> + ${info.cookidoo_count} Cookidoo-Rezepte einbeziehen
      </label>`;
    }

    const emptyCount = info.empty_slots.length;
    const selectAllState = emptyCount > 0 ? 'checked' : '';

    modalBody.innerHTML = `<form id="ai-config-form">
      <div class="ai-week-info">Woche: <strong>${weekLabel}</strong></div>
      <div class="ai-recipe-info">
        <span class="ai-recipe-badge">${info.local_count} lokale Rezepte</span>
        ${cookidooHtml}
      </div>
      <div class="ai-section-label">
        Slots auswaehlen
        <label class="ai-select-all"><input type="checkbox" id="ai-select-all" ${selectAllState}> Alle</label>
      </div>
      ${slotGrid}
      <div class="ai-form-fields">
        <div class="ai-form-field">
          <label>Portionen</label>
          <input type="number" name="servings" value="4" min="1" max="20" required>
        </div>
        <div class="ai-form-field ai-form-field-grow">
          <label>Besondere Wuensche (optional)</label>
          <input type="text" name="preferences" placeholder="z.B. vegetarisch, schnell, keine Fischgerichte...">
        </div>
      </div>
      <p class="modal-error" id="ai-config-error"></p>
      <div class="modal-footer">
        <button type="submit" class="btn-small btn-ai" id="ai-generate-btn">Vorschau generieren</button>
      </div>
    </form>`;

    const selAll = document.getElementById('ai-select-all');
    selAll.addEventListener('change', () => {
      modalBody.querySelectorAll('.ai-slot-cb').forEach(cb => { cb.checked = selAll.checked; });
    });
    modalBody.querySelectorAll('.ai-slot-cb').forEach(cb => {
      cb.addEventListener('change', () => {
        const all = modalBody.querySelectorAll('.ai-slot-cb');
        const checked = modalBody.querySelectorAll('.ai-slot-cb:checked');
        selAll.checked = all.length === checked.length;
        selAll.indeterminate = checked.length > 0 && checked.length < all.length;
      });
    });

    document.getElementById('ai-config-form').addEventListener('submit', async (e) => {
      e.preventDefault();
      const form = e.target;
      const errEl = document.getElementById('ai-config-error');
      errEl.textContent = '';

      const selectedSlots = [];
      form.querySelectorAll('.ai-slot-cb:checked').forEach(cb => {
        const [dt, slot] = cb.value.split('_');
        selectedSlots.push({ date: dt, slot });
      });
      if (!selectedSlots.length) { errEl.textContent = 'Bitte mindestens einen Slot auswaehlen.'; return; }

      const servings = parseInt(form.querySelector('[name="servings"]').value) || 4;
      const preferences = form.querySelector('[name="preferences"]').value.trim();
      const includeCookidoo = form.querySelector('[name="include_cookidoo"]')?.checked || false;

      const btn = document.getElementById('ai-generate-btn');
      btn.textContent = 'KI denkt nach...';
      btn.disabled = true;

      try {
        const result = await API.post('/api/ai/generate-meal-plan', {
          week_start: weekData.week_start,
          servings,
          preferences,
          selected_slots: selectedSlots,
          include_cookidoo: includeCookidoo,
        });
        _showPreviewStep(result.suggestions, closeM, {
          weekStart: weekData.week_start,
          servings, preferences, selectedSlots, includeCookidoo, info,
        }, result.reasoning);
      } catch (err) {
        errEl.textContent = err.message;
        btn.textContent = 'Vorschau generieren';
        btn.disabled = false;
      }
    });
  }

  function _showPreviewStep(suggestions, closeM, config, reasoning) {
    const modalBody = document.getElementById('modal-body');
    document.getElementById('modal-title').textContent = 'KI-Vorschlag pruefen';

    if (!suggestions.length) {
      modalBody.innerHTML = `<div class="ai-empty-state">
        <p>Die KI konnte keinen passenden Vorschlag erstellen. Versuche es mit anderen Einstellungen.</p>
        <div class="modal-footer">
          <button class="btn-small" id="ai-back-btn">Zurueck</button>
        </div></div>`;
      document.getElementById('ai-back-btn').addEventListener('click', () => _showConfigStep(config.info, closeM));
      return;
    }

    suggestions.sort((a, b) => a.date !== b.date ? a.date.localeCompare(b.date) : (a.slot === 'lunch' ? -1 : 1));

    const ws = new Date(config.weekStart + 'T00:00:00');
    let rows = '';
    for (const s of suggestions) {
      const d = new Date(s.date + 'T00:00:00');
      const dayIdx = Math.round((d - ws) / MS_PER_DAY);
      const dayLabel = DAY_FULL[dayIdx] || s.date;
      const slotLabel = SLOT_LABELS[s.slot] || s.slot;
      const srcBadge = s.source === 'cookidoo'
        ? '<span class="source-badge cookidoo">Cookidoo</span>'
        : '<span class="source-badge local">Lokal</span>';
      const diffBadge = s.difficulty
        ? `<span class="diff-badge ${App.DIFFICULTY_CLASS[s.difficulty] || ''}">${App.DIFFICULTY_LABELS[s.difficulty] || ''}</span>`
        : '';
      const timeStr = s.prep_time ? `${s.prep_time}'` : '';

      rows += `<tr>
        <td class="ai-prev-day">${dayLabel}</td>
        <td>${slotLabel}</td>
        <td><strong>${esc(s.recipe_title)}</strong>
          <div class="ai-prev-meta">${srcBadge} ${diffBadge} ${timeStr ? `<span class="ai-prev-time">${timeStr}</span>` : ''}</div></td>
        <td class="ai-prev-servings">${s.servings_planned}P</td>
      </tr>`;
    }

    const hasCookidoo = suggestions.some(s => s.source === 'cookidoo');
    const cookidooNote = hasCookidoo
      ? '<p class="ai-preview-note">Cookidoo-Rezepte werden bei Uebernahme automatisch importiert.</p>'
      : '';

    const reasoningBtn = reasoning
      ? '<button class="btn-small btn-reasoning" id="ai-reasoning-btn" title="Warum hat die KI das vorgeschlagen?">&#128161; Begruendung</button>'
      : '';

    modalBody.innerHTML = `
      <div class="ai-preview-info">
        ${suggestions.length} Mahlzeiten vorgeschlagen
        ${reasoningBtn}
      </div>
      ${cookidooNote}
      <div class="ai-preview-scroll">
        <table class="ai-preview-table">
          <thead><tr><th>Tag</th><th>Slot</th><th>Rezept</th><th>Port.</th></tr></thead>
          <tbody>${rows}</tbody>
        </table>
      </div>
      <p class="modal-error" id="ai-preview-error"></p>
      <div class="modal-footer ai-preview-actions">
        <button class="btn-small" id="ai-back-btn">Zurueck</button>
        <button class="btn-small btn-ai" id="ai-regen-btn">Neu generieren</button>
        <button class="btn-small btn-primary" id="ai-confirm-btn">Plan uebernehmen</button>
      </div>`;

    if (reasoning) {
      document.getElementById('ai-reasoning-btn').addEventListener('click', () => {
        _showReasoningPopup(reasoning);
      });
    }

    document.getElementById('ai-back-btn').addEventListener('click', () => _showConfigStep(config.info, closeM));

    document.getElementById('ai-regen-btn').addEventListener('click', async () => {
      const btn = document.getElementById('ai-regen-btn');
      const errEl = document.getElementById('ai-preview-error');
      btn.textContent = 'KI denkt nach...';
      btn.disabled = true;
      document.getElementById('ai-confirm-btn').disabled = true;
      errEl.textContent = '';

      try {
        const result = await API.post('/api/ai/generate-meal-plan', {
          week_start: config.weekStart,
          servings: config.servings,
          preferences: config.preferences,
          selected_slots: config.selectedSlots,
          include_cookidoo: config.includeCookidoo,
        });
        _showPreviewStep(result.suggestions, closeM, config, result.reasoning);
      } catch (err) {
        errEl.textContent = err.message;
        btn.textContent = 'Neu generieren';
        btn.disabled = false;
        document.getElementById('ai-confirm-btn').disabled = false;
      }
    });

    document.getElementById('ai-confirm-btn').addEventListener('click', async () => {
      const btn = document.getElementById('ai-confirm-btn');
      const errEl = document.getElementById('ai-preview-error');
      btn.textContent = 'Wird gespeichert...';
      btn.disabled = true;
      document.getElementById('ai-regen-btn').disabled = true;
      document.getElementById('ai-back-btn').disabled = true;
      errEl.textContent = '';

      try {
        const result = await API.post('/api/ai/confirm-meal-plan', {
          week_start: config.weekStart,
          items: suggestions,
        });

        closeM();

        if (result.meal_ids?.length) {
          lastAiMealIds = result.meal_ids;
          if (lastAiUndoTimeout) clearTimeout(lastAiUndoTimeout);
          lastAiUndoTimeout = setTimeout(() => { lastAiMealIds = null; render(); }, UNDO_TIMEOUT_MS);
        }

        await loadWeek();

        if (result.shopping_list_generated) {
          if (confirm(`${result.message}\n\nEinkaufsliste wurde erstellt. Zur Einkaufsliste wechseln?`)) {
            document.getElementById('tab-shopping').click();
          }
        }
      } catch (err) {
        errEl.textContent = err.message;
        btn.textContent = 'Plan uebernehmen';
        btn.disabled = false;
        document.getElementById('ai-regen-btn').disabled = false;
        document.getElementById('ai-back-btn').disabled = false;
      }
    });
  }

  function _showReasoningPopup(text) {
    const existing = document.getElementById('ai-reasoning-popup');
    if (existing) existing.remove();

    const popup = document.createElement('div');
    popup.id = 'ai-reasoning-popup';
    popup.className = 'ai-reasoning-overlay';
    popup.innerHTML = `<div class="ai-reasoning-box">
      <div class="ai-reasoning-header">
        <span>&#128161; KI-Begruendung</span>
        <button class="btn-icon ai-reasoning-close">&times;</button>
      </div>
      <div class="ai-reasoning-body">${esc(text)}</div>
    </div>`;

    document.body.appendChild(popup);

    const close = () => popup.remove();
    popup.querySelector('.ai-reasoning-close').addEventListener('click', close);
    popup.addEventListener('click', (e) => { if (e.target === popup) close(); });
  }

  async function undoAiPlan() {
    if (!lastAiMealIds) return;
    try {
      await API.post('/api/ai/undo-meal-plan', { meal_ids: lastAiMealIds });
      lastAiMealIds = null;
      if (lastAiUndoTimeout) { clearTimeout(lastAiUndoTimeout); lastAiUndoTimeout = null; }
      await loadWeek();
    } catch (err) {
      alert(err.message);
    }
  }

  function dismissUndo() {
    lastAiMealIds = null;
    if (lastAiUndoTimeout) { clearTimeout(lastAiUndoTimeout); lastAiUndoTimeout = null; }
    render();
  }

  async function generateShoppingList() {
    if (!weekData) return;
    try {
      await API.post('/api/shopping/generate', { week_start: weekData.week_start });
      document.getElementById('tab-shopping').click();
    } catch (err) { alert(err.message); }
  }

  /* ── Helpers ── */
  function mondayOf(d) {
    const r = new Date(d);
    const day = r.getDay();
    const diff = (day === 0 ? -6 : 1) - day;
    r.setDate(r.getDate() + diff);
    r.setHours(0, 0, 0, 0);
    return r;
  }

  function addDays(d, n) {
    const r = new Date(d);
    r.setDate(r.getDate() + n);
    return r;
  }

  function formatDateDE(d) {
    return d.toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit' });
  }

  function _showPantryDeductionToast(lines) {
    const existing = document.getElementById('pantry-deduction-toast');
    if (existing) existing.remove();
    const toast = document.createElement('div');
    toast.id = 'pantry-deduction-toast';
    toast.className = 'pantry-deduction-toast';
    toast.innerHTML = `<strong>Vorrat aktualisiert</strong><br>${lines.map(l => esc(l)).join('<br>')}`;
    document.body.appendChild(toast);
    setTimeout(() => { toast.classList.add('fade-out'); }, 4000);
    setTimeout(() => { toast.remove(); }, 5000);
  }

  return { init, loadWeek, assignSlot, editSlot: assignSlot, clearSlot, markCooked, undoAiPlan, dismissUndo };
})();
