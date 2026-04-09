/**
 * Family members management: list, add, edit, delete with color/emoji pickers.
 */
const Members = (() => {
  const COLORS = ['#0052CC','#00875A','#DE350B','#FF8B00','#6B778C','#8777D9','#E91E63','#00BCD4','#4CAF50','#FF5722'];
  const EMOJIS = ['👨','👩','👦','👧','👶','🧑','👴','👵','🐶','🐱','🦊','🐻'];

  function init() {
    document.getElementById('member-add-btn').addEventListener('click', () => openMemberModal());
  }

  async function refresh() {
    await App.loadSharedData();
    renderList();
  }

  function renderList() {
    const container = document.getElementById('member-list');
    if (App.members.length === 0) {
      container.innerHTML = '<p style="text-align:center;color:var(--text-light);padding:2rem">Noch keine Familienmitglieder angelegt.</p>';
      return;
    }
    container.innerHTML = App.members.map(m => `
      <div class="member-card">
        <div class="member-avatar" style="background:${m.color}20;border:2px solid ${m.color}">
          ${m.avatar_emoji}
        </div>
        <div class="member-info">
          <div class="member-name">${esc(m.name)}</div>
          <div style="font-size:0.8rem;color:var(--text-light)">Seit ${App.formatDate(m.created_at)}</div>
        </div>
        <div class="member-actions">
          <button class="btn-icon" onclick="Members.edit(${m.id})" title="Bearbeiten">&#9998;</button>
          <button class="btn-icon" onclick="Members.remove(${m.id})" title="Löschen">&times;</button>
        </div>
      </div>
    `).join('');
  }

  function openMemberModal(member) {
    const isEdit = !!member;
    const selectedColor = member?.color || COLORS[0];
    const selectedEmoji = member?.avatar_emoji || EMOJIS[0];

    const html = `<form>
      <label>Name</label>
      <input name="name" value="${esc(member?.name || '')}" required placeholder="z.B. Mama, Papa, Max...">
      <label>Farbe</label>
      <div class="checkbox-group" id="color-picker">
        ${COLORS.map(c => `<span class="chip ${c === selectedColor ? 'selected' : ''}" data-value="${c}" style="background:${c};color:white;border-color:${c}">&nbsp;&nbsp;&nbsp;</span>`).join('')}
      </div>
      <label>Avatar</label>
      <div class="checkbox-group" id="emoji-picker">
        ${EMOJIS.map(e => `<span class="chip ${e === selectedEmoji ? 'selected' : ''}" data-value="${e}" style="font-size:1.3rem">${e}</span>`).join('')}
      </div>
      <p class="modal-error" style="color:var(--red);font-size:0.85rem;min-height:1em"></p>
      <div class="modal-footer">
        ${isEdit ? `<button type="button" class="btn-small btn-danger" id="modal-delete-member">Löschen</button>` : ''}
        <button type="submit" class="btn-small btn-primary">${isEdit ? 'Speichern' : 'Hinzufügen'}</button>
      </div>
    </form>`;

    App.openModal(isEdit ? 'Mitglied bearbeiten' : 'Neues Familienmitglied', html, async (fd) => {
      const color = document.querySelector('#color-picker .chip.selected')?.dataset.value || COLORS[0];
      const emoji = document.querySelector('#emoji-picker .chip.selected')?.dataset.value || EMOJIS[0];
      const body = { name: fd.get('name'), color, avatar_emoji: emoji };

      if (isEdit) {
        await API.put(`/api/family-members/${member.id}`, body);
      } else {
        await API.post('/api/family-members/', body);
      }
      await refresh();
    });

    initSingleSelect('color-picker');
    initSingleSelect('emoji-picker');

    if (isEdit) {
      document.getElementById('modal-delete-member')?.addEventListener('click', async () => {
        if (confirm(`${member.name} wirklich entfernen?`)) {
          try {
            await API.delete(`/api/family-members/${member.id}`);
            App.closeModal();
            await refresh();
          } catch (err) { alert(err.message); }
        }
      });
    }
  }

  function initSingleSelect(containerId) {
    const chips = document.querySelectorAll(`#${containerId} .chip`);
    chips.forEach(chip => {
      chip.addEventListener('click', () => {
        chips.forEach(c => c.classList.remove('selected'));
        chip.classList.add('selected');
      });
    });
  }

  function edit(id) {
    const member = App.members.find(m => m.id === id);
    if (member) openMemberModal(member);
  }

  async function remove(id) {
    const member = App.members.find(m => m.id === id);
    if (member && confirm(`${member.name} wirklich entfernen?`)) {
      try {
        await API.delete(`/api/family-members/${id}`);
        await refresh();
      } catch (err) { alert(err.message); }
    }
  }

  return { init, refresh, edit, remove };
})();
