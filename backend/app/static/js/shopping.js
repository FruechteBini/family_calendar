/**
 * Shopping list module: category-grouped items, check-off, manual add,
 * AI store-sort, Knuspr integration.
 */
const Shopping = (() => {
  let shoppingList = null;
  let sortLoading = false;

  const CATEGORY_LABELS = {
    kuehlregal: 'Kuehlregal',
    obst_gemuese: 'Obst & Gemuese',
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

  const STORE_LABELS = {
    edeka: 'Edeka',
    lidl: 'Lidl',
    aldi: 'Aldi',
    penny: 'Penny',
    netto: 'Netto',
  };

  const SECTION_ICONS = {
    'Obst & Gemuese': '&#127813;',
    'Obst & Gemüse': '&#127813;',
    'Backwaren': '&#127838;',
    'Brot & Backwaren': '&#127838;',
    'Fleisch & Wurst': '&#129385;',
    'Kaese': '&#129472;',
    'Käse': '&#129472;',
    'Kuehlregal': '&#129472;',
    'Kühlregal': '&#129472;',
    'Molkereiprodukte': '&#129371;',
    'Tiefkuehl': '&#129482;',
    'Tiefkühl': '&#129482;',
    'Konserven & Trockenware': '&#129387;',
    'Trockenware': '&#129387;',
    'Gewuerze & Backen': '&#129474;',
    'Gewürze & Backen': '&#129474;',
    'Getraenke': '&#129380;',
    'Getränke': '&#129380;',
    'Suessigkeiten & Snacks': '&#127852;',
    'Süßigkeiten & Snacks': '&#127852;',
    'Suessigkeiten': '&#127852;',
    'Süßigkeiten': '&#127852;',
    'Drogerie & Haushalt': '&#129532;',
    'Drogerie': '&#129532;',
    'Sonstiges': '&#128230;',
    'Erledigt': '&#10003;',
  };

  function init() {
    document.getElementById('shopping-quick-add').addEventListener('click', quickAdd);
    document.getElementById('shopping-quick-input').addEventListener('keydown', (e) => {
      if (e.key === 'Enter') quickAdd();
    });
    const knusprBtn = document.getElementById('knuspr-send-btn');
    if (knusprBtn) knusprBtn.addEventListener('click', sendToKnuspr);

    const sortBtn = document.getElementById('shopping-ai-sort-btn');
    if (sortBtn) sortBtn.addEventListener('click', toggleStorePicker);

    const picker = document.getElementById('shopping-store-picker');
    if (picker) {
      picker.querySelectorAll('.store-btn').forEach(btn => {
        btn.addEventListener('click', () => sortByStore(btn.dataset.store));
      });
    }
  }

  function toggleStorePicker() {
    const picker = document.getElementById('shopping-store-picker');
    if (!picker) return;
    picker.classList.toggle('hidden');
  }

  async function sortByStore(store) {
    if (sortLoading) return;
    const picker = document.getElementById('shopping-store-picker');
    const sortBtn = document.getElementById('shopping-ai-sort-btn');
    sortLoading = true;
    if (sortBtn) { sortBtn.disabled = true; sortBtn.textContent = 'Sortiere...'; }
    if (picker) picker.classList.add('hidden');

    try {
      shoppingList = await API.post('/api/shopping/sort', { store });
      renderList();
    } catch (err) {
      alert('Sortierung fehlgeschlagen: ' + err.message);
    } finally {
      sortLoading = false;
      if (sortBtn) { sortBtn.disabled = false; sortBtn.textContent = 'Sortieren (KI)'; }
    }
  }

  async function refresh() {
    try {
      shoppingList = await API.get('/api/shopping/list');
    } catch { shoppingList = null; }
    renderList();
  }

  function renderList() {
    const container = document.getElementById('shopping-list');
    const progress = document.getElementById('shopping-progress');
    const sortBadge = document.getElementById('shopping-sort-badge');

    if (!shoppingList || !shoppingList.items || shoppingList.items.length === 0) {
      container.innerHTML = '<p style="text-align:center;color:var(--text-light);padding:2rem">Keine Einkaufsliste vorhanden. Generiere eine aus dem Wochenplan.</p>';
      if (progress) progress.textContent = '';
      if (sortBadge) { sortBadge.classList.add('hidden'); sortBadge.innerHTML = ''; }
      return;
    }

    const items = shoppingList.items;
    const total = items.length;
    const checked = items.filter(i => i.checked).length;
    if (progress) progress.textContent = `${checked}/${total} erledigt`;

    if (shoppingList.sorted_by_store) {
      const storeName = STORE_LABELS[shoppingList.sorted_by_store] || shoppingList.sorted_by_store;
      if (sortBadge) {
        sortBadge.classList.remove('hidden');
        sortBadge.innerHTML = `&#10024; Sortiert f&uuml;r <strong>${esc(storeName)}</strong>`;
      }
      renderStoreSorted(container, items);
    } else {
      if (sortBadge) { sortBadge.classList.add('hidden'); sortBadge.innerHTML = ''; }
      renderCategoryGrouped(container, items);
    }
  }

  function renderCategoryGrouped(container, items) {
    const grouped = {};
    for (const cat of CATEGORY_ORDER) grouped[cat] = [];
    for (const item of items) {
      const cat = CATEGORY_ORDER.includes(item.category) ? item.category : 'sonstiges';
      grouped[cat].push(item);
    }

    let html = '';
    for (const cat of CATEGORY_ORDER) {
      const catItems = grouped[cat];
      if (catItems.length === 0) continue;

      const catChecked = catItems.filter(i => i.checked).length;
      const allDone = catChecked === catItems.length;

      html += `<div class="shopping-category ${allDone ? 'all-done' : ''}">
        <div class="shopping-cat-header">
          <span class="shopping-cat-icon">${CATEGORY_ICONS[cat] || ''}</span>
          <span class="shopping-cat-name">${CATEGORY_LABELS[cat] || cat}</span>
          <span class="shopping-cat-count">${catChecked}/${catItems.length}</span>
        </div>
        <div class="shopping-cat-items">
          ${catItems.map(item => renderItem(item)).join('')}
        </div>
      </div>`;
    }
    container.innerHTML = html;
  }

  function renderStoreSorted(container, items) {
    const sorted = [...items].sort((a, b) => (a.sort_order ?? 9999) - (b.sort_order ?? 9999));

    const sections = [];
    let currentSection = null;
    for (const item of sorted) {
      const sec = item.store_section || 'Sonstiges';
      if (sec !== currentSection) {
        sections.push({ name: sec, items: [item] });
        currentSection = sec;
      } else {
        sections[sections.length - 1].items.push(item);
      }
    }

    let html = '';
    for (const sec of sections) {
      const secChecked = sec.items.filter(i => i.checked).length;
      const allDone = secChecked === sec.items.length;
      const icon = SECTION_ICONS[sec.name] || '&#128722;';

      html += `<div class="shopping-category ${allDone ? 'all-done' : ''}">
        <div class="shopping-cat-header shopping-store-section">
          <span class="shopping-cat-icon">${icon}</span>
          <span class="shopping-cat-name">${esc(sec.name)}</span>
          <span class="shopping-cat-count">${secChecked}/${sec.items.length}</span>
        </div>
        <div class="shopping-cat-items">
          ${sec.items.map(item => renderItem(item)).join('')}
        </div>
      </div>`;
    }
    container.innerHTML = html;
  }

  function renderItem(item) {
    const amountStr = item.amount ? `${item.amount}${item.unit ? ' ' + item.unit : ''}` : '';
    return `<div class="shopping-item ${item.checked ? 'checked' : ''}" onclick="Shopping.toggleCheck(${item.id})">
      <div class="shopping-check ${item.checked ? 'checked' : ''}">
        ${item.checked ? '&#10003;' : ''}
      </div>
      <div class="shopping-item-info">
        <span class="shopping-item-name">${esc(item.name)}</span>
        ${amountStr ? `<span class="shopping-item-amount">${esc(amountStr)}</span>` : ''}
      </div>
      <div class="shopping-item-actions">
        ${item.source === 'manual' ? `<button class="btn-icon" onclick="event.stopPropagation();Shopping.removeItem(${item.id})" style="font-size:0.85rem">&times;</button>` : ''}
      </div>
    </div>`;
  }

  async function toggleCheck(itemId) {
    try {
      await API.patch(`/api/shopping/items/${itemId}/check`);
      await refresh();
    } catch (err) { alert(err.message); }
  }

  async function removeItem(itemId) {
    try {
      await API.delete(`/api/shopping/items/${itemId}`);
      await refresh();
    } catch (err) { alert(err.message); }
  }

  async function quickAdd() {
    const input = document.getElementById('shopping-quick-input');
    const name = input.value.trim();
    if (!name) return;
    const category = document.getElementById('shopping-quick-category').value;
    try {
      await API.post('/api/shopping/items', { name, category });
      input.value = '';
      await refresh();
    } catch (err) { alert(err.message); }
  }

  async function sendToKnuspr() {
    if (!shoppingList) return;
    try {
      const unchecked = shoppingList.items.filter(i => !i.checked);
      if (unchecked.length === 0) {
        alert('Alle Artikel bereits abgehakt.');
        return;
      }
      await API.post(`/api/knuspr/cart/send-list/${shoppingList.id}`);
      alert('Einkaufsliste an Knuspr gesendet!');
    } catch (err) {
      alert('Knuspr-Fehler: ' + err.message);
    }
  }

  return { init, refresh, toggleCheck, removeItem };
})();
