/**
 * Recipes module: list, create, edit, delete recipes with full ingredient management
 * and Cookidoo import with images.
 */
const Recipes = (() => {
  let recipes = [];
  let cookidooAvailable = false;

  function init() {
    document.getElementById('recipe-add-btn').addEventListener('click', () => openRecipeForm());
    document.getElementById('cookidoo-import-btn').addEventListener('click', () => openCookidooBrowser());
    checkCookidoo();
  }

  async function checkCookidoo() {
    try {
      const st = await API.get('/api/cookidoo/status');
      cookidooAvailable = st.available;
    } catch { cookidooAvailable = false; }
  }

  async function refresh() {
    try {
      recipes = await API.get('/api/recipes/?sort_by=title&order=asc');
    } catch { recipes = []; }
    renderList();
  }

  /* ── Local Recipe List ── */
  function renderList() {
    const container = document.getElementById('recipe-list');
    if (!recipes.length) {
      container.innerHTML = `<div class="recipe-empty">
        <div style="font-size:2.5rem;margin-bottom:0.5rem">&#127859;</div>
        <p>Noch keine Rezepte vorhanden</p>
        <p style="font-size:0.85rem;color:var(--text-light)">Erstelle ein neues Rezept oder importiere aus Cookidoo</p>
      </div>`;
      return;
    }
    container.innerHTML = '<div class="recipe-grid">' + recipes.map(r => {
      const diffBadge = `<span class="diff-badge ${App.DIFFICULTY_CLASS[r.difficulty] || ''}">${App.DIFFICULTY_LABELS[r.difficulty] || r.difficulty}</span>`;
      const timeStr = formatPrepTime(r.prep_time_active_minutes, r.prep_time_passive_minutes);
      const ingCount = r.ingredients ? r.ingredients.length : 0;
      const srcBadge = r.source === 'cookidoo'
        ? '<span class="source-badge cookidoo">Cookidoo</span>'
        : r.source === 'web'
        ? '<span class="source-badge web">Web</span>'
        : '<span class="source-badge manual">Eigenes</span>';
      const lastCooked = r.last_cooked_at
        ? new Date(r.last_cooked_at).toLocaleDateString('de-DE')
        : null;
      const imgHtml = r.image_url
        ? `<div class="recipe-card-img" style="background-image:url('${r.image_url}')"></div>`
        : `<div class="recipe-card-img recipe-card-img-placeholder"><span>&#127858;</span></div>`;

      return `<div class="recipe-card" onclick="Recipes.detail(${r.id})">
        ${imgHtml}
        <div class="recipe-card-body">
          <div class="recipe-card-title">${esc(r.title)}</div>
          <div class="recipe-card-badges">${srcBadge} ${diffBadge}</div>
          <div class="recipe-card-meta">
            <span>&#128101; ${r.servings}</span>
            ${timeStr ? `<span>&#9202; ${timeStr}</span>` : ''}
            <span>&#127813; ${ingCount}</span>
          </div>
          <div class="recipe-card-footer">
            ${lastCooked ? `<span>Zuletzt: ${lastCooked}</span>` : '<span>Noch nie gekocht</span>'}
            <span>${r.cook_count}x gekocht</span>
          </div>
        </div>
        <button class="recipe-card-delete" onclick="event.stopPropagation();Recipes.remove(${r.id})" title="Loeschen">&times;</button>
      </div>`;
    }).join('') + '</div>';
  }

  function formatPrepTime(active, passive) {
    const parts = [];
    if (active) parts.push(`${active}'`);
    if (passive) parts.push(`+${passive}' passiv`);
    return parts.join(' ');
  }

  /* ── Recipe Detail (read-only) ── */
  async function openRecipeDetail(id) {
    let recipe;
    try { recipe = await API.get(`/api/recipes/${id}`); } catch { return; }

    const diffLabel = App.DIFFICULTY_LABELS[recipe.difficulty] || recipe.difficulty;
    const diffClass = App.DIFFICULTY_CLASS[recipe.difficulty] || '';
    const timeStr = formatPrepTime(recipe.prep_time_active_minutes, recipe.prep_time_passive_minutes);
    const srcLabel = recipe.source === 'cookidoo' ? 'Cookidoo' : recipe.source === 'web' ? 'Web' : 'Eigenes';
    const srcClass = recipe.source;
    const lastCooked = recipe.last_cooked_at ? new Date(recipe.last_cooked_at).toLocaleDateString('de-DE') : null;

    let html = '<div class="recipe-detail">';

    if (recipe.image_url) {
      html += `<img class="recipe-detail-hero" src="${esc(recipe.image_url)}" alt="" onerror="this.style.display='none'">`;
    }

    html += '<div class="recipe-detail-pills">';
    html += `<span class="source-badge ${srcClass}">${srcLabel}</span>`;
    html += `<span class="diff-badge ${diffClass}">${diffLabel}</span>`;
    html += `<span class="cd-pill">&#128101; ${recipe.servings} Portionen</span>`;
    if (timeStr) html += `<span class="cd-pill">&#9202; ${timeStr}</span>`;
    html += '</div>';

    html += '<div class="recipe-detail-stats">';
    html += `<span>${recipe.cook_count}x gekocht</span>`;
    if (lastCooked) html += `<span>Zuletzt: ${lastCooked}</span>`;
    html += '</div>';

    // Ingredients
    if (recipe.ingredients && recipe.ingredients.length) {
      html += `<div class="recipe-detail-section-header"><h5>Zutaten</h5><span class="cd-count">${recipe.ingredients.length}</span></div>`;
      html += '<div class="recipe-detail-ingredients">';
      for (const ing of recipe.ingredients) {
        const desc = [ing.amount, ing.unit].filter(Boolean).join(' ');
        html += `<div class="cd-ing-row"><span class="cd-ing-name">${esc(ing.name)}</span><span class="cd-ing-desc">${esc(desc)}</span></div>`;
      }
      html += '</div>';
    }

    // Instructions
    if (recipe.instructions) {
      html += `<div class="recipe-detail-section-header" style="margin-top:1rem"><h5>Zubereitung</h5></div>`;
      html += `<div class="recipe-instructions-preview">${esc(recipe.instructions).replace(/\n/g, '<br>')}</div>`;
    }

    // Notes
    if (recipe.notes) {
      html += `<div class="recipe-detail-section-header" style="margin-top:1rem"><h5>Notizen</h5></div>`;
      html += `<p class="recipe-detail-notes">${esc(recipe.notes).replace(/\n/g, '<br>')}</p>`;
    }

    // History
    if (recipe.history && recipe.history.length) {
      html += `<div class="recipe-detail-section-header" style="margin-top:1rem"><h5>Kochverlauf</h5></div>`;
      html += '<div class="recipe-detail-history">';
      for (const h of recipe.history.slice(0, 5)) {
        const d = new Date(h.cooked_at).toLocaleDateString('de-DE');
        const stars = h.rating ? ' — ' + '&#9733;'.repeat(h.rating) + '&#9734;'.repeat(5 - h.rating) : '';
        html += `<div class="recipe-history-row"><span>${d}</span><span>${h.servings_cooked} Portionen${stars}</span></div>`;
      }
      html += '</div>';
    }

    html += '</div>';

    const titleHtml = `<span style="flex:1">${esc(recipe.title)}</span><button class="btn-small btn-primary" id="recipe-detail-edit" style="margin-left:auto;font-size:0.8rem">&#9998; Bearbeiten</button>`;
    App.openModal(recipe.title, html);
    // Replace modal title with title + edit button
    const titleEl = document.getElementById('modal-title');
    titleEl.innerHTML = titleHtml;
    titleEl.style.display = 'flex';
    titleEl.style.alignItems = 'center';
    titleEl.style.gap = '0.75rem';

    document.getElementById('recipe-detail-edit').addEventListener('click', () => {
      openRecipeForm(id);
    });
  }

  /* ── Recipe Form (create/edit) ── */
  async function openRecipeForm(existingId) {
    let recipe = null;
    if (existingId) {
      try { recipe = await API.get(`/api/recipes/${existingId}`); } catch { return; }
    }

    const isEdit = !!recipe;
    const title = isEdit ? recipe.title : '';
    const servings = isEdit ? recipe.servings : 4;
    const activeMin = isEdit ? (recipe.prep_time_active_minutes || '') : '';
    const passiveMin = isEdit ? (recipe.prep_time_passive_minutes || '') : '';
    const diff = isEdit ? recipe.difficulty : 'medium';
    const instructions = isEdit ? (recipe.instructions || '') : '';
    const notes = isEdit ? (recipe.notes || '') : '';
    const ingredients = isEdit && recipe.ingredients ? recipe.ingredients : [];

    const ingredientRows = ingredients.map((ing, i) => ingredientRowHtml(i, ing)).join('');

    const html = `<form id="recipe-form">
      <label>Rezeptname</label>
      <input name="title" value="${esc(title)}" required placeholder="z.B. Spaghetti Bolognese">

      <div style="display:grid;grid-template-columns:1fr 1fr;gap:0.75rem">
        <div>
          <label>Portionen</label>
          <input type="number" name="servings" value="${servings}" min="1" max="20" required>
        </div>
        <div>
          <label>Schwierigkeitsgrad</label>
          <select name="difficulty">
            <option value="easy" ${diff==='easy'?'selected':''}>Einfach</option>
            <option value="medium" ${diff==='medium'?'selected':''}>Mittel</option>
            <option value="hard" ${diff==='hard'?'selected':''}>Aufwendig</option>
          </select>
        </div>
      </div>

      <div style="display:grid;grid-template-columns:1fr 1fr;gap:0.75rem">
        <div>
          <label>Aktive Zubereitungszeit (Min)</label>
          <input type="number" name="prep_time_active_minutes" value="${activeMin}" min="0" placeholder="z.B. 20">
        </div>
        <div>
          <label>Passive Wartezeit (Min)</label>
          <input type="number" name="prep_time_passive_minutes" value="${passiveMin}" min="0" placeholder="z.B. 45">
        </div>
      </div>

      <label>Zubereitung</label>
      <textarea name="instructions" rows="6" placeholder="Schritt-fuer-Schritt Anleitung...">${esc(instructions)}</textarea>

      <label>Notizen</label>
      <textarea name="notes" rows="2" placeholder="Tipps, Varianten...">${esc(notes)}</textarea>

      <label>Zutaten</label>
      <div id="ingredient-container">
        ${ingredientRows}
      </div>
      <button type="button" class="btn-small" id="add-ingredient-btn" style="margin-top:0.5rem">+ Zutat</button>

      <p class="modal-error" style="color:var(--red);font-size:0.85rem;min-height:1em"></p>
      <div class="modal-footer">
        ${isEdit ? `<button type="button" class="btn-small btn-danger" id="modal-delete-recipe">Loeschen</button>` : ''}
        <button type="submit" class="btn-small btn-primary">${isEdit ? 'Speichern' : 'Rezept anlegen'}</button>
      </div>
    </form>`;

    App.openModal(isEdit ? 'Rezept bearbeiten' : 'Neues Rezept', html, async (fd) => {
      const body = {
        title: fd.get('title'),
        servings: parseInt(fd.get('servings')) || 4,
        difficulty: fd.get('difficulty'),
        prep_time_active_minutes: fd.get('prep_time_active_minutes') ? parseInt(fd.get('prep_time_active_minutes')) : null,
        prep_time_passive_minutes: fd.get('prep_time_passive_minutes') ? parseInt(fd.get('prep_time_passive_minutes')) : null,
        instructions: fd.get('instructions') || null,
        notes: fd.get('notes') || null,
        ingredients: collectIngredients(),
      };

      if (isEdit) {
        await API.put(`/api/recipes/${recipe.id}`, body);
      } else {
        await API.post('/api/recipes/', body);
      }
      await refresh();
    });

    let ingredientIdx = ingredients.length;
    document.getElementById('add-ingredient-btn').addEventListener('click', () => {
      const container = document.getElementById('ingredient-container');
      container.insertAdjacentHTML('beforeend', ingredientRowHtml(ingredientIdx++, null));
    });

    if (isEdit) {
      document.getElementById('modal-delete-recipe')?.addEventListener('click', async () => {
        if (confirm('Rezept wirklich loeschen?')) {
          try {
            await API.delete(`/api/recipes/${recipe.id}`);
            App.closeModal();
            await refresh();
          } catch (err) { alert(err.message); }
        }
      });
    }
  }

  function ingredientRowHtml(idx, ing) {
    const name = ing ? esc(ing.name) : '';
    const amount = ing && ing.amount != null ? ing.amount : '';
    const unit = ing ? esc(ing.unit || '') : '';
    const cat = ing ? ing.category : 'sonstiges';
    return `<div class="ingredient-row" data-idx="${idx}">
      <input name="ing_name_${idx}" placeholder="Zutat" value="${name}" class="ing-name" required>
      <input name="ing_amount_${idx}" placeholder="Menge" value="${amount}" class="ing-amount" type="number" step="any" min="0">
      <input name="ing_unit_${idx}" placeholder="Einheit" value="${unit}" class="ing-unit">
      <select name="ing_cat_${idx}" class="ing-cat">
        <option value="sonstiges" ${cat==='sonstiges'?'selected':''}>Sonstiges</option>
        <option value="kuehlregal" ${cat==='kuehlregal'?'selected':''}>Kuehlregal</option>
        <option value="obst_gemuese" ${cat==='obst_gemuese'?'selected':''}>Obst/Gemuese</option>
        <option value="trockenware" ${cat==='trockenware'?'selected':''}>Trockenware</option>
        <option value="drogerie" ${cat==='drogerie'?'selected':''}>Drogerie</option>
      </select>
      <button type="button" class="btn-icon ing-remove" onclick="this.closest('.ingredient-row').remove()" title="Entfernen">&times;</button>
    </div>`;
  }

  function collectIngredients() {
    const rows = document.querySelectorAll('#ingredient-container .ingredient-row');
    const result = [];
    rows.forEach(row => {
      const name = row.querySelector('.ing-name').value.trim();
      if (!name) return;
      const amount = row.querySelector('.ing-amount').value;
      const unit = row.querySelector('.ing-unit').value.trim();
      const category = row.querySelector('.ing-cat').value;
      result.push({
        name,
        amount: amount ? parseFloat(amount) : null,
        unit: unit || null,
        category,
      });
    });
    return result;
  }

  /* ── Import Dialog (URL + Cookidoo) ── */
  let cachedCollections = null;
  let cachedShoppingList = null;
  let navStack = [];

  function _setModalWide(wide) {
    const modal = document.getElementById('modal');
    if (wide) modal.classList.add('modal-wide');
    else modal.classList.remove('modal-wide');
  }

  async function openCookidooBrowser() {
    navStack = [];
    _setModalWide(true);
    App.openModal('Rezepte Import', _renderImportHome());

    // Wire up URL import form
    document.getElementById('url-import-form')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      await _parseUrl();
    });

    // Wire up Cookidoo browse button
    document.getElementById('cookidoo-browse-btn')?.addEventListener('click', () => _openCookidooBrowser());
  }

  function _renderImportHome() {
    return `<div id="import-home">
      <div class="url-import-section">
        <h4>&#127760; Link zu Rezept-Webseite</h4>
        <p class="url-import-hint">Fuege einen Link von einer beliebigen Koch-Webseite ein (z.B. Chefkoch, Lecker, EatSmarter, ...)</p>
        <form id="url-import-form" class="url-import-bar">
          <input type="url" id="url-import-input" placeholder="https://www.chefkoch.de/rezepte/..." required>
          <button type="submit" class="btn-small btn-primary" id="url-import-btn">Rezept laden</button>
        </form>
        <p class="url-import-error hidden" id="url-import-error"></p>
      </div>
      <div class="import-divider"><span>oder</span></div>
      <div class="cookidoo-import-section">
        <h4>&#129379; Cookidoo / Thermomix</h4>
        <p class="url-import-hint">Durchsuche deine Cookidoo-Sammlungen und importiere Rezepte.</p>
        <button class="btn-small" id="cookidoo-browse-btn">Cookidoo durchsuchen</button>
      </div>
    </div>`;
  }

  async function _parseUrl() {
    const input = document.getElementById('url-import-input');
    const btn = document.getElementById('url-import-btn');
    const errEl = document.getElementById('url-import-error');
    const url = input.value.trim();
    if (!url) return;

    btn.disabled = true;
    btn.textContent = 'Lade...';
    errEl.classList.add('hidden');

    try {
      const preview = await API.post('/api/recipes/parse-url', { url });
      _showUrlPreview(preview, url);
    } catch (err) {
      errEl.textContent = err.message || 'Rezept konnte nicht geladen werden';
      errEl.classList.remove('hidden');
      btn.disabled = false;
      btn.textContent = 'Rezept laden';
    }
  }

  function _showUrlPreview(data, originalUrl) {
    _setModalWide(false);
    const ingRows = (data.ingredients || []).map((ing, i) => ingredientRowHtml(i, ing)).join('');
    const diffLabels = { easy: 'Einfach', medium: 'Mittel', hard: 'Aufwendig' };

    let html = '<div class="url-preview">';
    html += `<button class="cd-back-btn" onclick="Recipes._backToImportHome()">&#8592; Zurueck</button>`;

    if (data.image_url) {
      html += `<img class="cd-preview-hero" src="${esc(data.image_url)}" alt="" onerror="this.style.display='none'">`;
    }
    html += `<h3 class="cd-preview-title">${esc(data.title)}</h3>`;
    html += '<div class="cd-preview-pills">';
    html += `<span class="cd-pill">&#128101; ${data.servings} Portionen</span>`;
    if (data.prep_time_active_minutes) html += `<span class="cd-pill">&#9202; ${data.prep_time_active_minutes} Min aktiv</span>`;
    if (data.prep_time_passive_minutes) html += `<span class="cd-pill">&#9203; ${data.prep_time_passive_minutes} Min passiv</span>`;
    html += '</div>';

    if (data.ingredients && data.ingredients.length) {
      html += `<div class="cd-preview-ing-header"><h5>Zutaten</h5><span class="cd-count">${data.ingredients.length} Stueck</span></div>`;
      html += '<div class="cd-preview-ingredients">';
      for (const ing of data.ingredients) {
        const desc = [ing.amount, ing.unit].filter(Boolean).join(' ');
        html += `<div class="cd-ing-row">
          <span class="cd-ing-name">${esc(ing.name)}</span>
          <span class="cd-ing-desc">${esc(desc)}</span>
        </div>`;
      }
      html += '</div>';
    }

    if (data.instructions) {
      html += `<div class="cd-preview-ing-header" style="margin-top:1rem"><h5>Zubereitung</h5></div>`;
      html += `<div class="recipe-instructions-preview">${esc(data.instructions).replace(/\n/g, '<br>')}</div>`;
    }

    html += `<div class="cd-preview-footer">
      <button class="btn-small btn-primary" id="url-import-confirm" style="font-size:1rem;padding:0.6rem 1.5rem">&#10010; In meine Rezepte importieren</button>
    </div>`;
    html += '</div>';

    document.getElementById('modal-title').textContent = data.title;
    document.getElementById('modal-body').innerHTML = html;

    document.getElementById('url-import-confirm').addEventListener('click', async function() {
      this.disabled = true;
      this.textContent = 'Importiere...';
      try {
        const body = {
          title: data.title,
          source: 'web',
          servings: data.servings,
          prep_time_active_minutes: data.prep_time_active_minutes,
          prep_time_passive_minutes: data.prep_time_passive_minutes,
          difficulty: data.difficulty || 'medium',
          instructions: data.instructions || null,
          notes: data.source_url ? `Quelle: ${data.source_url}` : null,
          image_url: data.image_url,
          ingredients: (data.ingredients || []).map(ing => ({
            name: ing.name,
            amount: ing.amount,
            unit: ing.unit,
            category: ing.category || 'sonstiges',
          })),
        };
        await API.post('/api/recipes/', body);
        this.textContent = '\u2713 Importiert';
        this.classList.remove('btn-primary');
        this.classList.add('btn-success');
        await refresh();
        setTimeout(() => App.closeModal(), 800);
      } catch (err) {
        this.disabled = false;
        this.textContent = 'Importieren';
        alert('Import fehlgeschlagen: ' + err.message);
      }
    });
  }

  function _backToImportHome() {
    _setModalWide(true);
    document.getElementById('modal-title').textContent = 'Rezepte Import';
    document.getElementById('modal-body').innerHTML = _renderImportHome();
    document.getElementById('url-import-form')?.addEventListener('submit', async (e) => {
      e.preventDefault();
      await _parseUrl();
    });
    document.getElementById('cookidoo-browse-btn')?.addEventListener('click', () => _openCookidooBrowser());
  }

  async function _openCookidooBrowser() {
    document.getElementById('modal-body').innerHTML =
      '<div style="text-align:center;padding:3rem"><div class="spinner"></div><p style="margin-top:1rem;color:var(--text-light)">Lade Cookidoo-Daten...</p></div>';

    if (!cookidooAvailable) {
      try {
        const st = await API.get('/api/cookidoo/status');
        cookidooAvailable = st.available;
      } catch { cookidooAvailable = false; }
    }

    if (!cookidooAvailable) {
      document.getElementById('modal-body').innerHTML = `
        <div style="text-align:center;padding:3rem">
          <button class="cd-back-btn" onclick="Recipes._backToImportHome()" style="margin-bottom:1rem">&#8592; Zurueck</button>
          <div style="font-size:3rem;margin-bottom:1rem">&#128268;</div>
          <h4 style="margin-bottom:0.75rem;color:var(--text)">Cookidoo nicht verfuegbar</h4>
          <p style="color:var(--text-light);max-width:400px;margin:0 auto;line-height:1.6">
            Die Verbindung zu Cookidoo konnte nicht hergestellt werden.<br>
            Bitte stelle sicher, dass die <strong>cookidoo-api</strong> installiert ist und
            <strong>COOKIDOO_EMAIL</strong> sowie <strong>COOKIDOO_PASSWORD</strong> in der .env-Datei konfiguriert sind.
          </p>
        </div>`;
      return;
    }

    try {
      if (!cachedCollections) {
        [cachedCollections, cachedShoppingList] = await Promise.all([
          API.get('/api/cookidoo/collections'),
          API.get('/api/cookidoo/shopping-list'),
        ]);
      }
    } catch (err) {
      document.getElementById('modal-body').innerHTML = `
        <div style="text-align:center;padding:3rem">
          <button class="cd-back-btn" onclick="Recipes._backToImportHome()" style="margin-bottom:1rem">&#8592; Zurueck</button>
          <div style="font-size:3rem;margin-bottom:1rem">&#9888;</div>
          <h4 style="margin-bottom:0.75rem;color:var(--text)">Verbindungsfehler</h4>
          <p style="color:var(--text-light);max-width:400px;margin:0 auto">Cookidoo-Daten konnten nicht geladen werden: ${esc(err.message)}</p>
        </div>`;
      return;
    }

    _renderCookidooMain();
  }

  function _renderCookidooMain() {
    navStack = ['main'];
    const collections = cachedCollections;
    const shoppingList = cachedShoppingList;
    const shopCount = shoppingList.length;
    let html = '<div id="cookidoo-browser">';

    if (shopCount > 0) {
      html += `<div class="cd-section">
        <div class="cd-section-header">
          <h4>&#128722; Deine Cookidoo-Einkaufsliste</h4>
          <span class="cd-count">${shopCount} Rezepte</span>
        </div>
        <div class="cd-recipe-grid">
          ${shoppingList.map(r => _cookidooCard(r, true)).join('')}
        </div>
      </div>
      <hr style="border:0;border-top:1px solid var(--border);margin:1.25rem 0">`;
    }

    html += `<div class="cd-section">
      <div class="cd-section-header">
        <h4>&#128218; Sammlungen</h4>
        <span class="cd-count">${collections.length} Kochbuecher</span>
      </div>
      <div class="cd-collections-grid">`;

    collections.forEach((col, idx) => {
      const recipeCount = col.chapters.reduce((sum, ch) => sum + ch.recipes.length, 0);
      html += `<div class="cd-collection-card" onclick="Recipes.openCookidooCollection(${idx})">
        <div class="cd-collection-icon">&#128214;</div>
        <div class="cd-collection-info">
          <div class="cd-collection-name">${esc(col.name)}</div>
          <div class="cd-collection-meta">${recipeCount} Rezepte</div>
        </div>
        <div class="cd-collection-arrow">&#8250;</div>
      </div>`;
    });
    html += '</div></div></div>';

    document.getElementById('modal-title').textContent = 'Rezepte Import';
    document.getElementById('modal-body').innerHTML = html;
    _setModalWide(true);
  }

  function openCookidooCollection(idx) {
    const col = cachedCollections[idx];
    navStack = ['main', idx];

    let html = `<div id="cookidoo-browser">
      <button class="cd-back-btn" onclick="Recipes._goBack()">&#8592; Zurueck zu Sammlungen</button>
      <h4 style="margin:0.75rem 0">${esc(col.name)}</h4>`;

    if (col.description) {
      html += `<p style="font-size:0.85rem;color:var(--text-light);margin-bottom:1rem;max-width:600px">${esc(col.description).substring(0, 250)}</p>`;
    }

    for (const ch of col.chapters) {
      if (ch.recipes.length === 0) continue;
      html += `<div class="cd-section">
        <div class="cd-section-header"><h5>${esc(ch.name)}</h5></div>
        <div class="cd-recipe-grid">
          ${ch.recipes.map(r => _cookidooCard(r, false)).join('')}
        </div>
      </div>`;
    }
    html += '</div>';

    document.getElementById('modal-title').textContent = col.name;
    document.getElementById('modal-body').innerHTML = html;
    _setModalWide(true);
  }

  function _cookidooCard(r, hasThumb) {
    const timeMin = r.total_time ? Math.round(r.total_time / 60) : null;
    const id = r.cookidoo_id || r.id;
    const thumb = hasThumb && r.thumbnail ? r.thumbnail : null;

    const imgHtml = thumb
      ? `<img class="cd-card-thumb" src="${thumb}" alt="" loading="lazy">`
      : `<div class="cd-card-thumb cd-card-thumb-ph">&#127858;</div>`;

    const ingCount = r.ingredients ? r.ingredients.length : 0;

    return `<div class="cd-card" onclick="Recipes.previewCookidoo('${esc(id)}')">
      ${imgHtml}
      <div class="cd-card-body">
        <div class="cd-card-name">${esc(r.name)}</div>
        <div class="cd-card-meta">
          ${timeMin ? `<span>&#9202; ${timeMin} Min</span>` : ''}
          ${ingCount ? `<span>${ingCount} Zutaten</span>` : ''}
        </div>
      </div>
      <button class="btn-small btn-primary cd-card-import" onclick="event.stopPropagation();Recipes.importFromCookidoo('${esc(id)}',this)">+</button>
    </div>`;
  }

  function _goBack() {
    if (navStack.length <= 1) {
      _backToImportHome();
      return;
    }
    navStack.pop();
    const top = navStack[navStack.length - 1];
    if (top === 'main') {
      _renderCookidooMain();
    } else {
      openCookidooCollection(top);
    }
  }

  async function previewCookidoo(cookidooId) {
    document.getElementById('modal-body').innerHTML =
      '<div style="text-align:center;padding:3rem"><div class="spinner"></div><p style="margin-top:1rem;color:var(--text-light)">Lade Rezept...</p></div>';
    document.getElementById('modal-title').textContent = 'Rezept laden...';
    _setModalWide(false);

    try {
      const d = await API.get(`/api/cookidoo/recipes/${cookidooId}`);

      const timeActive = d.active_time ? Math.round(d.active_time / 60) : null;
      const timeTotal = d.total_time ? Math.round(d.total_time / 60) : null;
      const timePassive = (timeTotal && timeActive) ? Math.max(0, timeTotal - timeActive) : null;

      let html = '<div class="cd-preview">';
      html += `<button class="cd-back-btn" onclick="Recipes._goBack()" style="margin-bottom:0.75rem">&#8592; Zurueck</button>`;

      if (d.image) {
        html += `<img class="cd-preview-hero" src="${d.image}" alt="">`;
      }
      html += `<h3 class="cd-preview-title">${esc(d.name)}</h3>`;

      html += '<div class="cd-preview-pills">';
      if (d.difficulty) html += `<span class="diff-badge ${App.DIFFICULTY_CLASS[d.difficulty] || ''}">${App.DIFFICULTY_LABELS[d.difficulty] || d.difficulty}</span>`;
      html += `<span class="cd-pill">&#128101; ${d.serving_size || 4} Portionen</span>`;
      if (timeActive) html += `<span class="cd-pill">&#9202; ${timeActive} Min aktiv</span>`;
      if (timePassive && timePassive > 0) html += `<span class="cd-pill">&#9203; ${timePassive} Min passiv</span>`;
      html += '</div>';

      if (d.ingredients && d.ingredients.length) {
        html += `<div class="cd-preview-ing-header">
          <h5>Zutaten</h5>
          <span class="cd-count">${d.ingredients.length} Stueck</span>
        </div>`;
        html += '<div class="cd-preview-ingredients">';
        for (const ing of d.ingredients) {
          html += `<div class="cd-ing-row">
            <span class="cd-ing-name">${esc(ing.name)}</span>
            <span class="cd-ing-desc">${esc(ing.description || '')}</span>
          </div>`;
        }
        html += '</div>';
      }

      if (d.instructions) {
        html += `<div class="cd-preview-ing-header" style="margin-top:1rem"><h5>Zubereitung</h5></div>`;
        html += `<div class="recipe-instructions-preview">${esc(d.instructions).replace(/\n/g, '<br>')}</div>`;
      }

      if (d.url) {
        html += `<a href="${d.url}" target="_blank" rel="noopener" class="cd-link">Auf Cookidoo.de ansehen &#8599;</a>`;
      }

      html += `<div class="cd-preview-footer">
        <button class="btn-small btn-primary cd-preview-import-btn" onclick="Recipes.importFromCookidoo('${esc(cookidooId)}',this)">&#10010; In meine Rezepte importieren</button>
      </div>`;
      html += '</div>';

      document.getElementById('modal-title').textContent = d.name;
      document.getElementById('modal-body').innerHTML = html;
    } catch (err) {
      document.getElementById('modal-body').innerHTML =
        `<div style="padding:1rem"><button class="cd-back-btn" onclick="Recipes._goBack()">&#8592; Zurueck</button><p style="color:var(--red);margin-top:1rem">Fehler: ${esc(err.message)}</p></div>`;
      document.getElementById('modal-title').textContent = 'Fehler';
    }
  }

  async function importFromCookidoo(cookidooId, btn) {
    const origText = btn.textContent;
    btn.disabled = true;
    btn.textContent = 'Importiere...';
    try {
      await API.post(`/api/cookidoo/recipes/${cookidooId}/import`);
      btn.textContent = '\u2713 Importiert';
      btn.classList.remove('btn-primary');
      btn.classList.add('btn-success');
      await refresh();
    } catch (err) {
      btn.disabled = false;
      if (err.message && err.message.includes('bereits')) {
        btn.textContent = '\u2713 Bereits da';
        btn.disabled = true;
        btn.classList.remove('btn-primary');
      } else {
        btn.textContent = origText;
        alert('Import fehlgeschlagen: ' + err.message);
      }
    }
  }

  async function remove(id) {
    if (confirm('Rezept wirklich loeschen?')) {
      try {
        await API.delete(`/api/recipes/${id}`);
        await refresh();
      } catch (err) { alert(err.message); }
    }
  }

  return { init, refresh, edit: openRecipeForm, remove, openRecipeForm, openCookidooBrowser, openCookidooCollection, previewCookidoo, importFromCookidoo, _goBack, _backToImportHome };
})();
