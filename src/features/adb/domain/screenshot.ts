/** Captures a single screen snapshot from the selected ADB device. */
export interface ScreenshotService {
  capture(connectionId: string): Promise<string>;
  /** Saves the displayed snapshot through a native picker; false means cancelled. */
  save(image: string, connectionId: string): Promise<boolean>;
}
