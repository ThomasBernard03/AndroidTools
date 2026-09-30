export function formatSize(bytes: number | null): string {
  if (bytes === null) return '—'
  if (bytes < 1024) return `${bytes} o`
  const unit = Math.min(Math.floor(Math.log(bytes) / Math.log(1024)), 3)
  return `${(bytes / 1024 ** unit).toLocaleString('fr-FR', { maximumFractionDigits: 1 })} ${['o', 'Kio', 'Mio', 'Gio'][unit]}`
}

export function formatDate(seconds: number | null): string {
  if (seconds === null) return '—'
  return new Date(seconds * 1000).toLocaleString('fr-FR', {
    dateStyle: 'short',
    timeStyle: 'short',
  })
}
