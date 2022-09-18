import type { NextPage } from 'next'
import React, { useEffect, useState } from 'react'
import { AppLayout } from '../components/Layout'
import useUser from '../lib/useUser'

async function fetchApiDocs(token: string) {
  return fetch(process.env.NEXT_PUBLIC_BACKEND_ENDPOINT + '/apidocs', {
    method: 'GET',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer ' + token
    },
  })
}

const ApiDocs: NextPage = () => {
  // Fetch the user client-side
  const { user, token } = useUser()
  const [iFrameSrc, setiFrameSrc] = useState("")

  useEffect(() => {
    const setSrc = async () => {
      if (token) {
        const res = await fetchApiDocs(token)
        const blob = await res.blob()
        const urlObject = URL.createObjectURL(blob)
        setiFrameSrc(urlObject)
      }
    }
    setSrc()
  }, [token])

  // Server-render loading state
  if (!user) {
    return <AppLayout>Loading...</AppLayout>
  }

  return (
    <AppLayout padding={false}>
      <iframe className="w-full h-[calc(100vh-2.25rem)]" height="100%" src={iFrameSrc}></iframe>
    </AppLayout>
  )
}
export default ApiDocs
