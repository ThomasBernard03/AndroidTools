export interface AppError {
  code: string
  message: string
  details: string
}

export function toAppError(error: unknown): AppError {
  if (
    typeof error === 'object' &&
    error !== null &&
    'code' in error &&
    typeof error.code === 'string' &&
    'message' in error &&
    typeof error.message === 'string' &&
    'details' in error &&
    typeof error.details === 'string'
  ) {
    return { code: error.code, message: error.message, details: error.details }
  }
  return {
    code: 'unexpected',
    message: 'Une erreur inattendue est survenue. Réessayez.',
    details: error instanceof Error ? error.message : String(error),
  }
}
