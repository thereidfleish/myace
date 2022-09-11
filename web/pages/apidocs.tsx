import type { NextPage } from 'next'
import React, { useEffect, useState } from 'react'
import { AppLayout } from '../components/Layout'
import useUser from '../lib/useUser'
import { getToken } from '../lib/useUser'

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
  const { user } = useUser()
  const [iFrameSrc, setiFrameSrc] = useState("")

  useEffect(() => {
    const setSrc = async () => {
      const token = getToken()
      if (token) {
        const res = await fetchApiDocs(token)
        const blob = await res.blob()
        const urlObject = URL.createObjectURL(blob)
        setiFrameSrc(urlObject)
      }
    }
    setSrc()
  }, [])

  // Server-render loading state
  if (!user) {
    return <AppLayout user={user}>Loading...</AppLayout>
  }

  return (
    <AppLayout user={user}>
      <iframe className="w-full h-screen" src={iFrameSrc}></iframe>
    </AppLayout>
  )
}
export default ApiDocs
