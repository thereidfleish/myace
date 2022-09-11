import useUser from '../lib/useUser'
import { AppLayout } from '../components/Layout'

const Profile = () => {
  // Fetch the user client-side
  const { user } = useUser()

  // Server-render loading state
  if (!user) {
    return <AppLayout user={user}>Loading...</AppLayout>
  }

  // Once the user request finishes, show the user
  return (
    <AppLayout user={user}>
      <h1>Your Profile</h1>
      <pre>{JSON.stringify(user, null, 2)}</pre>
    </AppLayout>
  )
}

export default Profile
