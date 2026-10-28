export const DEFAULT_STAGE_COLOR = '#1F93FF';

// Colors for the stages a new pipeline starts with, in the same order as the
// PIPELINE.PIPELINE_FORM.DEFAULT_STAGES translations.
export const DEFAULT_STAGES = [
  { key: 'LEAD', color: '#1F93FF' },
  { key: 'CONTACTED', color: '#8E4EC6' },
  { key: 'PROPOSAL', color: '#F76B15' },
  { key: 'WON', color: '#30A46C' },
];

export const stageTotal = cards =>
  cards.reduce((total, card) => total + (card.value || 0), 0);

export const formatValue = (value, locale) =>
  new Intl.NumberFormat(locale.replace('_', '-'), {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(value);

// vuedraggable reports a drop on the list that receives the card as `added`
// and a drop inside the same list as `moved`. The source list's `removed`
// needs no request of its own, so it yields nothing.
export const moveFromDragChange = ({ added, moved }, stageId) => {
  const change = added || moved;
  if (!change) return null;
  return { card: change.element, stageId, position: change.newIndex };
};
