import '../styles/globals.css'
import type { AppProps } from 'next/app'
import { SWRConfig } from 'swr'
import fetchJson from '../lib/fetchJson'
import AppErrorContext from '../lib/error-context'
import { useState } from 'react'

function App({ Component, pageProps }: AppProps) {
  const [error, setError] = useState("")
  const providerValue = { error, setError }

  return (
    <SWRConfig
      value={{
        fetcher: (url: URL, token: string | undefined) => fetchJson(url, setError, token),
      }}
    >
      <AppErrorContext.Provider value={providerValue}>
        <Component {...pageProps} />
      </AppErrorContext.Provider>
    </SWRConfig>

  )
}

export default App
