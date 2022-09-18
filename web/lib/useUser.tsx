import { useEffect, useState } from 'react'
import Router, { useRouter } from 'next/router'
import useSWR from 'swr'
import jwt_decode from 'jwt-decode'

export type User = {
  user_id: string
  username: string
  display_name: string
  biography: string
  email: string
  created_at: string
  updated_at: string | null
}

export function logout(setToken: any) {
  if (typeof window !== "undefined") {
    window.localStorage.removeItem('jwt')
    setToken('')
    // mutateUser(undefined)
    console.log("cleared jwt, token, and user")
    Router.push("/")
  }
}

// extract the user ID field from the JWT
function userIdFromJWT(token: string) {
  if (!token) {
    throw Error('cannot decode JWT: ' + token)
  }
  const decoded: any = jwt_decode(token)
  return decoded.user_id
}

export default function useUser({
  redirectTo = '',
} = {}) {

  const router = useRouter()

  const [token, setToken] = useState(() => {
    // get the stored token
    if (typeof window !== "undefined") {
      const saved = window.localStorage.getItem('jwt')
      return saved || ''
    } else {
      console.error('failed to retrieve stored JWT because window is undefined')
      return ''
    }
  });

  const { data: user, mutate: mutateUser, error } = useSWR<User>(
    // if token is empty string, do not make the request
    token == '' ? null :
      [
        process.env.NEXT_PUBLIC_BACKEND_ENDPOINT + '/users/' + userIdFromJWT(token),
        token
      ])

  useEffect(() => {
    // sync `token` application state with localStorage
    localStorage.setItem('jwt', token)

    // redirect to login page if logged out
    if (token == '' && router.pathname != '/' && router.pathname != '/login') {
      console.log('redirecting to login page')
      router.push('/login')
    }
  }, [token, router])

  // redirect to `redirectTo` if logged in
  useEffect(() => {
    if (!redirectTo) return
    const loggedIn = user?.user_id !== undefined && user.user_id !== null

    if (redirectTo && loggedIn) {
      router.push(redirectTo)
    }
  }, [redirectTo, user, router])

  return { user, mutateUser, token, setToken, error }
}
