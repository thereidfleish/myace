import { useEffect, useState } from 'react'
import useUser, { User } from '../lib/useUser'

function calcInitials(user: User | undefined): string {
  const initials = (user: User | undefined) => {
    if (!user) return ''

    // try to extract from display name
    if (user.display_name) {
      const names = user.display_name.split(' ')

      if (names.length >= 2 && names.at(0) && names.at(1)) {
        // take first char of first two names
        const initials = '' + names.at(0)?.at(0) + names.at(1)?.at(0)
        return initials
      }

      // take first two chars of first name
      const firstTwo = names.at(0)?.slice(0, 2)
      if (!firstTwo) return ''
      return firstTwo
    }

    // take firt two of username
    return user.username.slice(0, 2)

  }
  return initials(user).toUpperCase()


}

export default function Avatar() {
  const { user } = useUser()
  const [initials, setInitials] = useState(calcInitials(user))

  useEffect(() => {
    setInitials(calcInitials(user))
  }, [user])

  return (
    <div className="avatar placeholder">
      <div className="bg-neutral-focus text-neutral-content rounded-full w-48">
        <span className="text-3xl">{initials}</span>
      </div>
    </div>
  )

}
