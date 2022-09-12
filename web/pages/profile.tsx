import useUser from '../lib/useUser'
import { AppLayout } from '../components/Layout'
import { useEffect, useState } from 'react'

const Profile = () => {
  // Fetch the user client-side
  const { user, mutateUser, token } = useUser()
  const [username, setUsername] = useState('')
  const [displayName, setDisplayName] = useState('')
  const [bio, setBio] = useState('')
  const [curPassword, setCurPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  useEffect(() => {
    if (user) {
      setUsername(user.username)
      setDisplayName(user.display_name)
      setBio(user.biography)
    }
  }, [user])

  // Server-render loading state
  if (!user) {
    return <AppLayout>Loading...</AppLayout>
  }

  const handleProfileEdit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    // clear status messages
    setError("")
    setSuccess("")

    // create an interface for the body
    interface changeUserBody {
      username?: string,
      display_name?: string,
      biography?: string,
      password?:
      {
        old_password: string,
        new_password: string
      }
    }

    // dynamically construct the body based off of filled fields
    let body: changeUserBody = {
      username,
      display_name: displayName,
      biography: bio
    }
    if (curPassword && !newPassword || !curPassword && newPassword) {
      setError("both password fields must be filled")
      return
    }
    if (curPassword && newPassword) {
      body.password = {
        old_password: curPassword,
        new_password: newPassword
      }
    }

    // make the request
    const res = await fetch(process.env.NEXT_PUBLIC_BACKEND_ENDPOINT + '/users/me', {
      method: 'PATCH',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
      },
      body: JSON.stringify(body)
    })

    // handle response
    if (res.status == 200) {
      // parse the token
      const user = await res.json()
      mutateUser(user)
      setSuccess("account updated")
    } else {
      const error = await res.json()
      console.error(error)
      setError(error.error)
    }
  }

  // Once the user request finishes, show the user
  return (
    <AppLayout>

      <div className="bg-base-dark-800 rounded-md shadow-2xl shadow-base-dark-700 p-5">
        <h1 className="text-2xl">Account</h1>

        <div className="m-4">
          <p>Joined {user.created_at}</p>
          {user.updated_at &&
            <p>Last edited {user.updated_at}</p>
          }
        </div>

        <form onSubmit={handleProfileEdit}>
          {error &&
            <p className="text-error">{error}</p>}
          {success &&
            <p className="text-success">{success}</p>}

          <div className="grid sm:grid-cols-2">
            <section className="my-4">
              <h2 className="text-xl">Basic</h2>
              <div className="form-control w-full max-w-xs">
                <label className="label"><span className="label-text">Email Address</span></label>
                <input type="text" placeholder={user.email} className="input input-bordered w-full max-w-xs" disabled />
              </div>
              <div className="form-control w-full max-w-xs">
                <label className="label"><span className="label-text">Username</span></label>
                <input type="text" value={username} className="input input-bordered w-full max-w-xs" onChange={(e) => setUsername(e.target.value)} />
              </div>
              <div className="form-control w-full max-w-xs">
                <label className="label"><span className="label-text">Display Name</span></label>
                <input type="text" value={displayName} className="input input-bordered w-full max-w-xs" onChange={(e) => setDisplayName(e.target.value)} />
              </div>
              <div className="form-control w-full max-w-xs">
                <label className="label"><span className="label-text">Biography</span></label>
                <input type="text" value={bio} className="input input-bordered w-full max-w-xs" onChange={(e) => setBio(e.target.value)} />
              </div>
            </section>

            <section className="my-4">
              <h2 className="text-xl">Security</h2>
              <div className="form-control w-full max-w-xs">
                <label className="label"><span className="label-text">Current Password</span></label>
                <input type="password" className="input input-bordered w-full max-w-xs" onChange={(e) => setCurPassword(e.target.value)} />
              </div>
              <div className="form-control w-full max-w-xs">
                <label className="label"><span className="label-text">New Password</span></label>
                <input type="password" className="input input-bordered w-full max-w-xs" onChange={(e) => setNewPassword(e.target.value)} />
              </div>
            </section>
          </div>
          <button className="mt-4 btn btn-primary">Save</button>
        </form>
      </div>
    </AppLayout>
  )
}

export default Profile
