import React from 'react'

// the default value if a component tries to access context without a provider above it in the tree
// this is impossible bc we are wrapping the entire application in this provider
// these are just default values to be used for typing. The provider in _app.tsx
// will set the values.
export const AppErrorContext = React.createContext({
  error: '',
  setError: (_: string) => { }
})

export default AppErrorContext
