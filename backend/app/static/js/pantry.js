/**
 * Pantry module: category-grouped items, alerts for low stock / expiring,
 * quick-add, edit, delete, add-to-shopping-list.
 */
const Pantry = (() => {
  let pantryItems = [];
  let alerts = [];

  const CATEGORY_LABELS = {
    kuehlregal: 'Kühlregal',
    obst_gemuese: 'Obst & Gemüse',
    trockenware: 'Trockenware',
    drogerie: 'Drogerie',
    sonstiges: 'Sonstiges',
  };
  const CATEGORY_ICONS = {
    kuehlregal: '&#129472;',
    obst_gemuese: '&#127813;',
    trockenware: '&#127838;',
    drogerie: '&#129532;',
    sonstiges: '&#128230;',
  };
  const CATEGORY_ORDER = ['kuehlregal', 'obst_gemuese', 'trockenware', 'drogerie', 'sonstiges'];

  function init() {
    document.getElementById('pantry-quick-add').addEventListener('click', quickAdd);
    document.getElementById('pantry-quick-input').addEventListener('keydown', (e) => {
      if (e.key === 'Enter') quickAdd();
    });
  }

  async function refresh() {
    try {
      pantryItems = await API.get('/api/pantry/');
    } catch { pantryItems = []; }
    try {
      alerts = await API.get('/api/pantry/alerts');
    } catch { alerts = []; }
    renderAlerts();
    renderList();
    updateBadge();
  }

  function updateBadge() {
    const badge = document.getElementById('pantry-alert-badge');
    const count = document.getElementById('pantry-item-count');
    if (badge) {
      if (alerts.length > 0) {
        badge.classList.remove('hidden');
        badge.textContent = alerts.length + ' Warnung' + (alerts.length > 1 ? 'en' : '');
      } else {
        badge.classList.add('hidden');
      }
    }
    if (count) {
      count.textContent = pantryItems.length + ' Artikel';
    }
  }

  function renderAlerts() {
    const container = document.getElementById('pantry-alerts');
    if (!container) return;
    if (alerts.length === 0) {
      container.classList.add('hidden');
      container.innerHTML = '';
      return;
    }

    container.classList.remove('hidden');
    let html = '<div class="pantry-alert-header">&#9888; Vorrat prüfen</div>';
    html += '<div class="pantry-alert-items">';
    for (const a of alerts) {
      const reason = a.reason === 'low_stock'
        ? (a.amount !== null ? `Nur noch ${a.amount}${a.unit ? ' ' + a.unit : ''} vorhanden` : 'Niedrig')
        : `Läuft ab: ${formatExpiry(a.expiry_date)}`;
      html += `<div class="pantry-alert-item">
        <div class="pantry-alert-info">
          <strong>${esc(a.name)}</strong>
          <span class="pantry-alert-reason">${reason}</span>
        </div>
        <div class="pantry-alert-actions">
          <button class="btn-small btn-primary" onclick="Pantry.addToShopping(${a.id})">Zur Einkaufsliste</button>
          <button class="btn-small" onclick="Pantry.dismissAlert(${a.id})">Noch vorhanden</button>
        </div>
      </div>`;
    }
    html += '</div>';
    container.innerHTML = html;
  }

  function renderList() {
    const container = document.getElementById('pantry-list');
    if (!container) return;

    if (pantryItems.length === 0) {
      container.innerHTML = '<p style="text-align:center;color:var(--text-light);padding:2rem">Vorratskammer ist leer. Füge Artikel hinzu oder nutze einen Sprachbefehl.</p>';
      return;
    }

    const grouped = {};
    for (const cat of CATEGORY_ORDER) grouped[cat] = [];
    for (const item of pantryItems) {
      const cat = CATEGORY_ORDER.includes(item.category) ? item.category : 'sonstiges';
      grouped[cat].push(item);
    }

    let html = '';
    for (const cat of CATEGORY_ORDER) {
      const items = grouped[cat];
      if (items.length === 0) continue;

      html += `<div class="pantry-category">
        <div class="pantry-cat-header">
          <span class="pantry-cat-icon">${CATEGORY_ICONS[cat] || ''}</span>
          <span class="pantry-cat-name">${CATEGORY_LABELS[cat] || cat}</span>
          <span class="pantry-cat-count">${items.length}</span>
        </div>
        <div class="pantry-cat-items">
          ${items.map(renderItem).join('')}
        </div>
      </div>`;
    }
    container.innerHTML = html;
  }

  function renderItem(item) {
    const amountStr = item.amount !== null ? `${item.amount}${item.unit ? ' ' + item.unit : ''}` : '';
    const expiryStr = item.expiry_date ? formatExpiry(item.expiry_date) : '';

    let statusClass = '';
    if (item.is_low_stock && item.amount !== null && item.amount <= 0) statusClass = 'depleted';
    else if (item.is_low_stock) statusClass = 'low-stock';
    else if (item.is_expiring_soon) statusClass = 'expiring';

    return `<div class="pantry-item ${statusClass}">
      <div class="pantry-item-info">
        <span class="pantry-item-name">${esc(item.name)}</span>
        ${amountStr ? `<span class="pantry-item-amount">${esc(amountStr)}</span>` : '<span class="pantry-item-amount pantry-unknown-qty">Menge unbekannt</span>'}
        ${expiryStr ? `<span class="pantry-expiry-badge${item.is_expiring_soon ? ' expiring' : ''}">${esc(expiryStr)}</span>` : ''}
      </div>
      <div class="pantry-item-actions">
        <button class="btn-icon" onclick="Pantry.editItem(${item.id})" title="Bearbeiten">&#9998;</button>
        <button class="btn-icon" onclick="Pantry.deleteItem(${item.id})" title="Löschen">&times;</button>
      </div>
    </div>`;
  }

  function formatExpiry(dateStr) {
    if (!dateStr) return '';
    const d = new Date(dateStr + 'T00:00:00');
    const day = d.getDate();
    if (day === 1) {
      return 'ca. ' + d.toLocaleDateString('de-DE', { month: 'long', year: 'numeric' });
    }
    return d.toLocaleDateString('de-DE', { day: 'numeric', month: 'short', year: 'numeric' });
  }

  async function quickAdd() {
    const nameInput = document.getElementById('pantry-quick-input');
    const name = nameInput.value.trim();
    if (!name) return;

    const amount = parseFloat(document.getElementById('pantry-quick-amount').value) || null;
    const unit = document.getElementById('pantry-quick-unit').value.trim() || null;
    const category = document.getElementById('pantry-quick-category').value;
    const expiryInput = document.getElementById('pantry-quick-expiry');
    const expiry = expiryInput.value || null;

    try {
      await API.post('/api/pantry/', { name, amount, unit, category, expiry_date: expiry });
      nameInput.value = '';
      document.getElementById('pantry-quick-amount').value = '';
      document.getElementById('pantry-quick-unit').value = '';
      expiryInput.value = '';
      await refresh();
    } catch (err) { alert(err.message); }
  }

  function editItem(itemId) {
    const item = pantryItems.find(i => i.id === itemId);
    if (!item) return;

    const html = `<form>
      <label>Name</label>
      <input type="text" name="name" value="${esc(item.name)}" required>
      <label>Menge</label>
      <input type="number" name="amount" value="${item.amount !== null ? item.amount : ''}" step="0.1" placeholder="Unbekannt">
      <label>Einheit</label>
      <input type="text" name="unit" value="${item.unit || ''}" placeholder="z.B. Dosen, kg, Stück">
      <label>Kategorie</label>
      <select name="category">
        ${CATEGORY_ORDER.map(c => `<option value="${c}" ${item.category === c ? 'selected' : ''}>${CATEGORY_LABELS[c]}</option>`).join('')}
      </select>
      <label>Ablaufdatum</label>
      <input type="date" name="expiry_date" value="${item.expiry_date || ''}">
      <label>Mindestbestand (Warnung ab)</label>
      <input type="number" name="min_stock" value="${item.min_stock !== null ? item.min_stock : ''}" step="0.1" placeholder="Standard: 2">
      <p class="modal-error" style="color:var(--red);font-size:0.85rem;min-height:1em"></p>
      <div class="modal-footer">
        <button type="submit" class="btn-small btn-primary">Speichern</button>
      </div>
    </form>`;

    App.openModal('Vorrat bearbeiten', html, async (fd) => {
      const payload = {};
      const name = fd.get('name')?.trim();
      if (name) payload.name = name;
      const amount = fd.get('amount');
      payload.amount = amount !== '' && amount !== null ? parseFloat(amount) : null;
      const unit = fd.get('unit')?.trim();
      payload.unit = unit || null;
      payload.category = fd.get('category');
      const expiry = fd.get('expiry_date');
      payload.expiry_date = expiry || null;
      const minStock = fd.get('min_stock');
      payload.min_stock = minStock !== '' && minStock !== null ? parseFloat(minStock) : null;
      await API.patch(`/api/pantry/${itemId}`, payload);
      await refresh();
    });
  }

  async function deleteItem(itemId) {
    try {
      await API.delete(`/api/pantry/${itemId}`);
      await refresh();
    } catch (err) { alert(err.message); }
  }

  async function addToShopping(itemId) {
    try {
      await API.post(`/api/pantry/alerts/${itemId}/add-to-shopping`, {});
      await refresh();
    } catch (err) { alert(err.message); }
  }

  async function dismissAlert(itemId) {
    try {
      await API.post(`/api/pantry/alerts/${itemId}/dismiss`, {});
      await refresh();
    } catch (err) { alert(err.message); }
  }

  return { init, refresh, editItem, deleteItem, addToShopping, dismissAlert };
})();
