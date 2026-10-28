import { stageTotal, formatValue, moveFromDragChange } from '../helpers';

describe('pipeline helpers', () => {
  it('sums the card values and skips cards without one', () => {
    expect(stageTotal([{ value: 10.5 }, { value: null }, { value: 4 }])).toBe(
      14.5
    );
    expect(stageTotal([])).toBe(0);
  });

  it('formats the value for the account locale', () => {
    expect(formatValue(1234.5, 'pt_BR')).toBe('1.234,50');
    expect(formatValue(1234.5, 'en')).toBe('1,234.50');
  });

  describe('moveFromDragChange', () => {
    const card = { id: 7 };

    it('moves the card into the stage that received it', () => {
      expect(
        moveFromDragChange({ added: { element: card, newIndex: 2 } }, 4)
      ).toEqual({ card, stageId: 4, position: 2 });
    });

    it('moves the card inside its own stage', () => {
      expect(
        moveFromDragChange(
          { moved: { element: card, oldIndex: 0, newIndex: 1 } },
          4
        )
      ).toEqual({ card, stageId: 4, position: 1 });
    });

    it('ignores the removal from the source stage', () => {
      expect(
        moveFromDragChange({ removed: { element: card, oldIndex: 0 } }, 3)
      ).toBeNull();
    });
  });
});
