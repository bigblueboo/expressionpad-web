import type { Store } from '../core/state'

/** Apply the saved preference and keep System mode in sync with the device. */
export function bindTheme(store: Store, onChange: () => void): () => void {
  const media = window.matchMedia('(prefers-color-scheme: dark)')
  const apply = () => {
    const preference = store.state.appearance.theme
    const theme =
      preference === 'system' ? (media.matches ? 'dark' : 'light') : preference
    if (document.documentElement.dataset.theme === theme) return
    document.documentElement.dataset.theme = theme
    document
      .querySelector('meta[name="theme-color"]')
      ?.setAttribute('content', theme === 'dark' ? '#292d29' : '#deddd4')
    onChange()
  }
  const unsubscribe = store.subscribe(apply)
  media.addEventListener('change', apply)
  apply()
  return () => {
    unsubscribe()
    media.removeEventListener('change', apply)
  }
}
