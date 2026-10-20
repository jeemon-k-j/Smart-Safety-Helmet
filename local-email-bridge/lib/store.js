'use strict';

function createMemoryStore() {
  const seen = new Set();
  return {
    has: (id) => seen.has(id),
    add: (id) => {
      seen.add(id);
    },
    size: () => seen.size,
  };
}

module.exports = { createMemoryStore };
