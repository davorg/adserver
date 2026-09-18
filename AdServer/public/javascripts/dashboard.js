(() => {
  'use strict';
  const form = document.getElementById('graph-form');
  const status = document.getElementById('graph-status');
  const output = document.getElementById('graph-output');
  const keys = ['metric', 'scope', 'from', 'to'];
  let pending;
  let sequence = 0;

  function element(tag, text, attrs = {}, svg = false) {
    const node = svg ? document.createElementNS('http://www.w3.org/2000/svg', tag) : document.createElement(tag);
    if (text !== null) node.textContent = text;
    for (const [name, value] of Object.entries(attrs)) node.setAttribute(name, value);
    return node;
  }

  function render(data) {
    form.elements.metric.value = data.metric;
    form.elements.scope.replaceChildren(...data.options.map(option =>
      element('option', option.label, { value: option.value })));
    form.elements.scope.value = data.scope;
    form.elements.from.value = data.from;
    form.elements.to.value = data.to;
    const max = Math.max(1, ...data.points.map(point => Number(point.count)));
    const points = data.points.map((point, i) => ({ ...point,
      x: data.points.length === 1 ? 450 : 60 + 780 * i / (data.points.length - 1),
      y: 250 - 210 * Number(point.count) / max
    }));
    const svg = element('svg', null, { viewBox: '0 0 900 300', role: 'img', 'aria-labelledby': 'chart-title chart-description' }, true);
    svg.append(element('title', `Daily ${data.metric} — ${data.label}`, { id: 'chart-title' }, true),
      element('desc', `Dates ${data.from} through ${data.to}. Counts from 0 to ${max}. Exact values are in the daily table.`, { id: 'chart-description' }, true),
      element('path', null, { d: 'M60 40 H840 M60 250 H840', stroke: '#dce5e1', fill: 'none' }, true));
    for (const [x, y, text, anchor] of [[50, 45, max, 'end'], [50, 255, 0, 'end'], [60, 280, data.from, 'start'], [840, 280, data.to, 'end']]) {
      svg.append(element('text', text, { x, y, 'text-anchor': anchor, 'font-size': 14, fill: '#526662' }, true));
    }
    svg.append(element('polyline', null, { points: points.map(p => `${p.x},${p.y}`).join(' '), stroke: '#176b58', 'stroke-width': 3, fill: 'none' }, true));
    for (const point of points) {
      const circle = element('circle', null, { cx: point.x, cy: point.y, r: 3, fill: '#176b58' }, true);
      circle.append(element('title', `${point.day}: ${point.count} ${data.metric}`, {}, true));
      svg.append(circle);
    }
    const details = element('details', null);
    details.append(element('summary', 'View daily values'));
    const scroll = element('div', null, { class: 'table-scroll' });
    const table = element('table', null);
    const head = element('thead', null);
    const headings = element('tr', null);
    headings.append(element('th', 'Date', { scope: 'col' }), element('th', data.metric, { scope: 'col', class: 'number' }));
    head.append(headings);
    const body = element('tbody', null);
    for (const point of data.points) {
      const row = element('tr', null);
      row.append(element('th', point.day, { scope: 'row' }), element('td', point.count, { class: 'number' }));
      body.append(row);
    }
    table.append(head, body);
    scroll.append(table);
    details.append(scroll);
    output.replaceChildren(svg, details);
    status.textContent = `${data.label} · ${data.total} ${data.metric} from ${data.from} through ${data.to}. Dates use the database’s time zone.${Number(data.total) === 0 ? ' No activity in this range.' : ''}`;
  }

  async function load(params) {
    pending?.abort();
    pending = new AbortController();
    const current = ++sequence;
    status.textContent = 'Loading graph…';
    output.replaceChildren();
    form.setAttribute('aria-busy', 'true');
    try {
      const response = await fetch(`${form.dataset.endpoint}?${params}`, { signal: pending.signal, headers: { Accept: 'application/json' } });
      const data = await response.json();
      if (current !== sequence) return;
      if (!response.ok) throw new Error(data.error || 'Unable to load graph. Please try again.');
      render(data);
      const url = new URL(window.location.href);
      for (const key of keys) url.searchParams.set(key, data[key]);
      window.history.replaceState(null, '', url);
    } catch (error) {
      if (current === sequence && error.name !== 'AbortError') {
        status.textContent = error.message || 'Unable to load graph. Please try again.';
      }
    } finally {
      if (current === sequence) form.removeAttribute('aria-busy');
    }
  }

  function update(event) {
    event.preventDefault();
    if (form.reportValidity()) load(new URLSearchParams(new FormData(form)));
  }
  form.addEventListener('submit', update);
  form.addEventListener('change', update);
  const initial = new URLSearchParams();
  const url = new URL(window.location.href);
  for (const key of keys) {
    if (url.searchParams.has(key)) initial.set(key, url.searchParams.get(key));
  }
  // Keep dates editable if a bookmarked request is invalid or the request fails.
  for (const key of ['from', 'to']) form.elements[key].value = initial.get(key) || '';
  load(initial);
})();
