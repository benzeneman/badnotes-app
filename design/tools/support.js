// A small stand-in for the mockup tool's runtime, so the .dc.html screens
// render in a plain browser: fills {{...}} from renderVals(), expands
// <sc-for>/<sc-if>, inlines <dc-import> screens and moves <helmet> into
// <head>. Used by render.mjs to take pictures of every screen.
(() => {
  class DCLogic {
    constructor(props) {
      this.props = props;
      this.state = {};
    }
    setState(s) {
      Object.assign(this.state, s);
    }
    renderVals() {
      return {};
    }
  }
  window.DCLogic = DCLogic;

  const sources = {};
  function load(name) {
    if (sources[name] != null) return sources[name];
    const xhr = new XMLHttpRequest();
    xhr.open('GET', `./${name}.dc.html`, false);
    xhr.send();
    return (sources[name] = xhr.responseText);
  }

  function parse(html) {
    const doc = new DOMParser().parseFromString(html, 'text/html');
    const root = doc.querySelector('x-dc');
    const script = doc.querySelector('script[type="text/x-dc"]');
    let props = {};
    try {
      props = JSON.parse(script?.dataset.props ?? '{}');
    } catch (_) {}
    delete props.$preview;
    return { root, code: script?.textContent ?? '', props };
  }

  function makeComponent(code, props) {
    const Component = new Function('DCLogic', `${code}; return Component;`)(
      DCLogic,
    );
    return new Component(props);
  }

  function evaluate(expr, scope) {
    const keys = Object.keys(scope);
    try {
      return new Function(...keys, `return (${expr});`)(
        ...keys.map((k) => scope[k]),
      );
    } catch (_) {
      return undefined;
    }
  }

  const whole = /^\s*\{\{([\s\S]+?)\}\}\s*$/;
  const parts = /\{\{([\s\S]+?)\}\}/g;

  function fill(text, scope) {
    return text.replace(parts, (_, e) => {
      const v = evaluate(e, scope);
      return v == null || typeof v === 'function' ? '' : String(v);
    });
  }

  function value(raw, scope) {
    if (raw == null) return undefined;
    const m = raw.match(whole);
    return m ? evaluate(m[1], scope) : raw;
  }

  function processChildren(node, scope) {
    for (const child of [...node.childNodes]) processNode(child, scope);
  }

  function processNode(node, scope) {
    if (node.nodeType === Node.TEXT_NODE) {
      if (node.nodeValue.includes('{{')) node.nodeValue = fill(node.nodeValue, scope);
      return;
    }
    if (node.nodeType !== Node.ELEMENT_NODE) return;
    const tag = node.tagName.toLowerCase();

    if (tag === 'sc-for') {
      const list = value(node.getAttribute('list'), scope) ?? [];
      const as = node.getAttribute('as') || 'item';
      const out = document.createDocumentFragment();
      (Array.isArray(list) ? list : []).forEach((item, i) => {
        const copy = node.cloneNode(true);
        processChildren(copy, { ...scope, [as]: item, index: i });
        out.append(...copy.childNodes);
      });
      node.replaceWith(out);
      return;
    }
    if (tag === 'sc-if') {
      const v = value(node.getAttribute('value'), scope);
      if (v && v !== 'false') {
        processChildren(node, scope);
        node.replaceWith(...node.childNodes);
      } else {
        node.remove();
      }
      return;
    }
    if (tag === 'dc-import') {
      const props = {};
      for (const a of [...node.attributes]) {
        if (a.name === 'name' || a.name.startsWith('hint-')) continue;
        props[camel(a.name)] = value(a.value, scope);
      }
      const rendered = render(node.getAttribute('name'), props);
      node.replaceWith(...rendered.childNodes);
      return;
    }

    for (const a of [...node.attributes]) {
      if (/^on[a-z]/i.test(a.name)) {
        node.removeAttribute(a.name);
      } else if (a.value.includes('{{')) {
        node.setAttribute(a.name, fill(a.value, scope));
      }
    }
    processChildren(node, scope);
  }

  function camel(s) {
    return s.replace(/-([a-z])/g, (_, c) => c.toUpperCase());
  }

  function moveHelmet(root) {
    const helmet = root.querySelector(':scope > helmet');
    if (!helmet) return;
    for (const child of [...helmet.childNodes]) {
      document.head.append(document.importNode(child, true));
    }
    helmet.remove();
  }

  /// Renders screen [name] with [props]; returns its x-dc element.
  function render(name, props) {
    const { root, code, props: own } = parse(load(name));
    const el = document.importNode(root, true);
    moveHelmet(el);
    const comp = makeComponent(code, { ...own, ...props });
    let vals = {};
    try {
      vals = comp.renderVals() ?? {};
    } catch (e) {
      console.error(name, e);
    }
    processChildren(el, vals);
    return el;
  }

  function main() {
    const root = document.querySelector('x-dc');
    if (!root) return;
    const script = document.querySelector('script[type="text/x-dc"]');
    let props = {};
    try {
      props = JSON.parse(script?.dataset.props ?? '{}');
    } catch (_) {}
    delete props.$preview;
    moveHelmet(root);
    const comp = makeComponent(script?.textContent ?? '', props);
    let vals = {};
    try {
      vals = comp.renderVals() ?? {};
    } catch (e) {
      console.error(e);
    }
    processChildren(root, vals);
    document.body.dataset.rendered = 'true';
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', main);
  } else {
    main();
  }
})();
