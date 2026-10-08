import type { ScreenshotService } from '../domain/screenshot';

/** Explicit illustration for development demos, never used as a real-device fallback. */
export function createDemoScreenshotService(): ScreenshotService {
  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="360" height="780" viewBox="0 0 360 780">
    <defs><linearGradient id="sky" x2="1" y2="1"><stop stop-color="#dce9fb"/><stop offset="1" stop-color="#7394ca"/></linearGradient></defs>
    <rect width="360" height="780" fill="url(#sky)"/>
    <circle cx="300" cy="430" r="240" fill="#174ea6" opacity=".2"/>
    <circle cx="60" cy="670" r="210" fill="#fffef9" opacity=".35"/>
    <g fill="#103d85" font-family="sans-serif" text-anchor="middle">
      <text x="180" y="170" font-size="72">09:41</text>
      <text x="180" y="208" font-size="18">Thursday, October 8</text>
      <text x="180" y="400" font-size="26">Android Tools</text>
      <text x="180" y="434" font-size="16">Simulated screen</text>
    </g>
    <rect x="28" y="646" width="304" height="68" rx="34" fill="#fffef9" opacity=".8"/>
    <g fill="#174ea6"><circle cx="76" cy="680" r="19"/><circle cx="145" cy="680" r="19"/><circle cx="214" cy="680" r="19"/><circle cx="283" cy="680" r="19"/></g>
    <rect x="128" y="754" width="104" height="5" rx="2.5" fill="#103d85"/>
  </svg>`;
  return {
    async save() {
      return true;
    },
    async capture() {
      return `data:image/svg+xml,${encodeURIComponent(svg)}`;
    },
  };
}
