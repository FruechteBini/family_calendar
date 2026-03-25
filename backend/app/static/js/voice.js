/**
 * Voice command module: speech recognition via Web Speech API,
 * sends transcribed text to AI backend, displays results.
 */
const Voice = (() => {
  let recognition = null;
  let isListening = false;
  let btn = null;
  let fabIcon = null;
  let silenceTimer = null;
  let finalTranscript = '';

  const SpeechRecognition = window.SpeechRecognition || window.webkitSpeechRecognition;
  const SILENCE_TIMEOUT_MS = 5000;

  const ACTION_LABELS = {
    create_event: 'Termin erstellt',
    create_recurring_event: 'Serientermin erstellt',
    create_todo: 'Aufgabe erstellt',
    create_recipe: 'Rezept erstellt',
    set_meal_slot: 'Essensplan belegt',
    generate_meal_plan: 'Essensplan erstellt',
    add_shopping_item: 'Einkaufsartikel hinzugefuegt',
    add_pantry_items: 'Vorrat aktualisiert',
    complete_todo: 'Aufgabe erledigt',
    mark_cooked: 'Als gekocht markiert',
    update_event: 'Termin bearbeitet',
    update_todo: 'Aufgabe bearbeitet',
    delete_event: 'Termin geloescht',
    delete_todo: 'Aufgabe geloescht',
  };

  function init() {
    btn = document.getElementById('voice-cmd-btn');
    if (!btn) return;
    fabIcon = btn.querySelector('.voice-fab-icon');

    if (!SpeechRecognition) {
      btn.addEventListener('click', openTextFallback);
      btn.title = 'Sprachbefehl (Texteingabe)';
      return;
    }

    recognition = new SpeechRecognition();
    recognition.lang = 'de-DE';
    recognition.continuous = true;
    recognition.interimResults = true;
    recognition.maxAlternatives = 1;

    recognition.onresult = (e) => {
      let interim = '';
      finalTranscript = '';
      for (let i = 0; i < e.results.length; i++) {
        if (e.results[i].isFinal) {
          finalTranscript += e.results[i][0].transcript;
        } else {
          interim += e.results[i][0].transcript;
        }
      }
      resetSilenceTimer();
    };

    recognition.onerror = (e) => {
      clearSilenceTimer();
      if (e.error === 'no-speech') {
        stopListening();
        return;
      }
      stopListening();
      if (e.error !== 'aborted') {
        showError('Spracherkennung fehlgeschlagen: ' + e.error);
      }
    };

    recognition.onend = () => {
      clearSilenceTimer();
      if (isListening) {
        const text = finalTranscript.trim();
        isListening = false;
        btn.classList.remove('listening');
        fabIcon.innerHTML = '&#127908;';
        btn.title = 'Sprachbefehl';
        if (text) {
          sendCommand(text);
        }
      }
    };

    btn.addEventListener('click', toggle);
  }

  function toggle() {
    if (isListening) {
      recognition.stop();
    } else {
      startListening();
    }
  }

  function startListening() {
    try {
      finalTranscript = '';
      recognition.start();
      isListening = true;
      btn.classList.add('listening');
      fabIcon.innerHTML = '&#9899;';
      btn.title = 'Aufnahme laeuft... (klicken zum Stoppen)';
      resetSilenceTimer();
    } catch { /* already started */ }
  }

  function stopListening() {
    clearSilenceTimer();
    if (isListening) {
      isListening = false;
      recognition.stop();
    }
    btn.classList.remove('listening');
    fabIcon.innerHTML = '&#127908;';
    btn.title = 'Sprachbefehl';
  }

  function resetSilenceTimer() {
    clearSilenceTimer();
    silenceTimer = setTimeout(() => {
      if (isListening) recognition.stop();
    }, SILENCE_TIMEOUT_MS);
  }

  function clearSilenceTimer() {
    if (silenceTimer) { clearTimeout(silenceTimer); silenceTimer = null; }
  }

  function setProcessing(on) {
    if (on) {
      btn.classList.add('processing');
      btn.disabled = true;
      fabIcon.innerHTML = '&#8987;';
    } else {
      btn.classList.remove('processing');
      btn.disabled = false;
      fabIcon.innerHTML = '&#127908;';
    }
  }

  async function sendCommand(text) {
    setProcessing(true);
    try {
      const result = await API.post('/api/ai/voice-command', { text });
      showResult(result, text);
      refreshActiveView();
    } catch (err) {
      showError(err.message || 'Fehler bei der Verarbeitung');
    } finally {
      setProcessing(false);
    }
  }

  function openTextFallback() {
    const html = `<form>
      <label>Sprachbefehl als Text eingeben</label>
      <input type="text" name="voice_text" placeholder="z.B. Morgen um 10 Uhr Arzttermin..." required autofocus
        style="font-size:1rem;padding:0.6rem">
      <p class="modal-error" style="color:var(--red);font-size:0.85rem;min-height:1em"></p>
      <div class="modal-footer">
        <button type="submit" class="btn-small btn-primary">Ausfuehren</button>
      </div>
    </form>`;

    App.openModal('Sprachbefehl', html, async (fd) => {
      const text = fd.get('voice_text')?.trim();
      if (!text) throw new Error('Bitte einen Befehl eingeben');
      await sendCommand(text);
    });
  }

  function showResult(response, inputText) {
    const existing = document.getElementById('voice-result-popup');
    if (existing) existing.remove();

    let actionsHtml = '';
    for (const action of response.actions) {
      const label = ACTION_LABELS[action.type] || action.type;
      const hasError = action.result?.error;
      const icon = hasError ? '&#10060;' : '&#9989;';

      if (action.type === 'generate_meal_plan' && !hasError && action.result?.meal_details) {
        const r = action.result;
        let mealsHtml = r.meal_details.map(m => `<div class="voice-meal-item">&#127869; ${esc(m)}</div>`).join('');
        let extraInfo = `${r.meals_created} Mahlzeiten geplant`;
        if (r.shopping_list_generated) extraInfo += ' + Einkaufsliste erstellt';
        actionsHtml += `<div class="voice-action-item">${icon} <strong>${esc(label)}</strong>
          <span class="voice-action-detail">${esc(extraInfo)}</span></div>
          <div class="voice-meal-plan-details">${mealsHtml}</div>`;
        if (r.reasoning) {
          actionsHtml += `<div class="voice-meal-reasoning"><em>&#128161; ${esc(r.reasoning)}</em></div>`;
        }
      } else {
        let detailText = action.result?.title || action.result?.name || action.result?.id?.toString() || '';
        if (action.result?.count) detailText += ` (${action.result.count}x)`;
        const detail = hasError
          ? `<span class="voice-action-error">${esc(action.result.error)}</span>`
          : `<span class="voice-action-detail">${esc(detailText)}</span>`;
        actionsHtml += `<div class="voice-action-item">${icon} <strong>${esc(label)}</strong> ${detail}</div>`;
      }
    }

    const popup = document.createElement('div');
    popup.id = 'voice-result-popup';
    popup.className = 'voice-result-overlay';
    popup.innerHTML = `<div class="voice-result-box">
      <div class="voice-result-header">
        <span>&#127908; Sprachbefehl ausgefuehrt</span>
        <button class="btn-icon voice-result-close">&times;</button>
      </div>
      <div class="voice-result-body">
        <div class="voice-result-input">"${esc(inputText)}"</div>
        <div class="voice-result-summary">${esc(response.summary)}</div>
        <div class="voice-result-actions">${actionsHtml}</div>
      </div>
    </div>`;

    document.body.appendChild(popup);

    const close = () => popup.remove();
    popup.querySelector('.voice-result-close').addEventListener('click', close);
    popup.addEventListener('click', (e) => { if (e.target === popup) close(); });
  }

  function showError(message) {
    const existing = document.getElementById('voice-result-popup');
    if (existing) existing.remove();

    const popup = document.createElement('div');
    popup.id = 'voice-result-popup';
    popup.className = 'voice-result-overlay';
    popup.innerHTML = `<div class="voice-result-box">
      <div class="voice-result-header voice-result-header-error">
        <span>&#9888; Fehler</span>
        <button class="btn-icon voice-result-close">&times;</button>
      </div>
      <div class="voice-result-body">
        <p style="color:var(--red)">${esc(message)}</p>
      </div>
    </div>`;

    document.body.appendChild(popup);

    const close = () => popup.remove();
    popup.querySelector('.voice-result-close').addEventListener('click', close);
    popup.addEventListener('click', (e) => { if (e.target === popup) close(); });
  }

  function refreshActiveView() {
    try {
      const active = document.querySelector('.view:not(.hidden)');
      if (!active) return;
      const id = active.id;
      if (id === 'view-calendar') Calendar.refresh();
      else if (id === 'view-todos') Todos.refresh();
      else if (id === 'view-meals') {
        Meals.loadWeek();
        const pantryTab = document.getElementById('subtab-pantry');
        if (pantryTab && !pantryTab.classList.contains('hidden')) Pantry.refresh();
      }
      else if (id === 'view-members') Members.refresh();
    } catch { /* view might not have refresh */ }
  }

  return { init };
})();
