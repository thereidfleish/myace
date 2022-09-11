import { useEffect } from 'react'
import Router, { useRouter } from 'next/router'
import useSWR from 'swr'
import { FetchError } from './fetchJson'

export type User = {
  user_id: string
  username: string
  display_name: string
  biography: string
  email: string
  created_at: string
  updated_at: string | null
}

export function getToken() {
  if (typeof window !== "undefined") {
    return window.sessionStorage.getItem('jwt')
  }
}

export function setToken(token: string) {
  if (typeof window !== "undefined") {
    window.sessionStorage.setItem('jwt', token)
  }
}

export function logout() {
  if (typeof window !== "undefined") {
    window.sessionStorage.removeItem('jwt')
    Router.push("/")
  }
}

export default function useUser({
  redirectTo = '',
} = {}) {

  const { data: user, mutate: mutateUser, error } = useSWR<User>([
    process.env.NEXT_PUBLIC_BACKEND_ENDPOINT + '/users/da09ba14-2cc8-11ed-a33c-6bb3e507074f',
    getToken()
  ])

  const router = useRouter()

  if (error instanceof FetchError && router.pathname != '/login') {
    console.error(error)
    console.log("redirecting to /login from " + router.pathname)
    router.push("/login")
    // clear cache
    mutateUser(undefined)
  }

  useEffect(() => {
    console.log(user)
    // if no redirect needed, just return (example: already on /dashboard)
    // if user data not yet there (fetch in progress, logged in or not) then don't do anything yet
    if (!redirectTo || !user) return

    const loggedIn = user?.user_id !== undefined && user.user_id !== null

    if (redirectTo && loggedIn) {
      Router.push(redirectTo)
    }
  }, [user, redirectTo, error])

  return { user, mutateUser }
}
