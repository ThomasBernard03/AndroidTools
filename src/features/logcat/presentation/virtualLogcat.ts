export const ROW_HEIGHT = 20;
export const MAX_SCROLL_HEIGHT = 1_000_000;

/** Keep the scrollbar within browser layout limits, even for millions of lines. */
export function scrollGeometry(total: number, height: number) {
  const rows = Math.max(1, Math.floor(height / ROW_HEIGHT));
  const maxOffset = Math.max(0, total - rows);
  const scrollHeight = Math.max(
    height,
    Math.min(MAX_SCROLL_HEIGHT, total * ROW_HEIGHT),
  );
  return {
    rows,
    maxOffset,
    scrollHeight,
    maxScroll: Math.max(0, scrollHeight - height),
  };
}
export function offsetToScroll(offset: number, total: number, height: number) {
  const { maxOffset, maxScroll } = scrollGeometry(total, height);
  return maxOffset
    ? (Math.min(maxOffset, Math.max(0, offset)) / maxOffset) * maxScroll
    : 0;
}
export function scrollToOffset(scroll: number, total: number, height: number) {
  const { maxOffset, maxScroll } = scrollGeometry(total, height);
  return maxScroll
    ? Math.round(
        (Math.min(maxScroll, Math.max(0, scroll)) / maxScroll) * maxOffset,
      )
    : 0;
}
