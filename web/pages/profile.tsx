import useUser from '../lib/useUser'
import { AppLayout } from '../components/Layout'
import { useEffect, useState } from 'react'
import Avatar from '../components/Avatar';

function ProfileInput({ type = "text", label, value, setState, disabled = false }: { type?: string, label: string, value: string, setState: any, disabled?: boolean }) {

  return (
    <div className="form-control w-full max-w-xs my-2">
      <label className="label"><span className="label-text text-neutral-content">{label}</span></label>
      <input type={type} value={value} className="input input-bordered w-full max-w-xs" onChange={(e) => { console.log(e); setState(e.target.value) }} disabled={disabled} />
    </div>
  )
}

const Profile = () => {
  // Fetch the user client-side
  const { user, mutateUser, token } = useUser()
  const [username, setUsername] = useState('')
  const [usernameAvailable, setUsernameAvailable] = useState(true)
  const [displayName, setDisplayName] = useState('')
  const [bio, setBio] = useState('')
  const [curPassword, setCurPassword] = useState('')
  const [newPassword, setNewPassword] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')
  const [success, setSuccess] = useState('')

  useEffect(() => {
    if (user) {
      setUsername(user.username)
      setDisplayName(user.display_name)
      setBio(user.biography)
    }
  }, [user])

  useEffect(() => {
    // check if username is available
    const checkUsername = async () => {
      // don't check if username has not changed
      if (username === user?.username) {
        return
      }

      // make the request
      const res = await fetch(process.env.NEXT_PUBLIC_BACKEND_ENDPOINT + '/usernames/' + username + '/check', {
        method: 'GET',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + token
        }
      })

      // handle response
      if (res.status == 200) {
        const isAvailable = await res.json().then(res => res.available)
        setUsernameAvailable(isAvailable)
      } else {
        const error = await res.json()
        console.error(error)
        setError(error.error)
      }
    }
    checkUsername()
  })

  // Server-render loading state
  if (!user) {
    return <AppLayout>Loading...</AppLayout>
  }

  const onProfileSave = async (e: React.FormEvent<HTMLFormElement>) => {
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
    setSaving(true);
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
      const user = await res.json()
      mutateUser(user)
      setSuccess("account updated")
    } else {
      const error = await res.json()
      console.error(error)
      setError(error.error)
    }
    setSaving(false)
  }

  return (
    <AppLayout>

      <div className="mx-auto max-w-5xl rounded-md shadow-xl shadow-base-300 p-5 bg-neutral">
        <h1 className="text-2xl text-neutral-content">Account</h1>

        <div className="flex flex-wrap mt-5">
          <div className="mx-auto sm:ml-0 sm:mr-6">
            <Avatar />
          </div>
          <div className="w-fit my-4 text-neutral-content">
            <p>Joined {user.created_at}</p>
            {user.updated_at &&
              <p>Last edited {user.updated_at}</p>
            }
          </div>
        </div>

        <form onSubmit={onProfileSave}>
          <div className="grid sm:grid-cols-2 gap-y-4 gap-x-8">
            <section className="my-4">
              <h2 className="text-xl text-neutral-content">Basic</h2>
              <ProfileInput type="email" label="Email Address" value={user.email} setState={() => { }} disabled />

              {/* check username in real time */}
              <div className="form-control w-full max-w-xs">
                <label className="label"><span className="label-text text-neutral-content">Username</span>
                  {/* add 'available' or 'unavailable' label */}
                  {
                    (() => {
                      // no label if username has not changed
                      if (username == user.username) return ''
                      if (usernameAvailable)
                        return <span className="label-text-alt text-success font-semibold">Username Available</span>
                      else
                        return <span className="label-text-alt text-error font-semibold">Username Taken</span>
                    })()
                  }
                </label>
                <input type="text" value={username}
                  className={
                    "input input-bordered w-full max-w-xs " +
                    // show border if username has changed and is/isn't available
                    (username == user.username ? '' :
                      usernameAvailable ? 'input-success' : 'input-error')
                  } onChange={e => setUsername(e.target.value)} />
              </div>

              <ProfileInput label="Display Name" value={displayName} setState={setDisplayName} />
              <ProfileInput label="Biography" value={bio} setState={setBio} />
            </section>

            <section className="my-4">
              <h2 className="text-xl text-neutral-content">Change Password</h2>
              <ProfileInput type="password" label="Current Password" value={curPassword} setState={setCurPassword} />
              <ProfileInput type="password" label="New Password" value={newPassword} setState={setNewPassword} />
            </section>
          </div>
          {error &&
            <p className="text-error">{error}</p>}
          {success &&
            <p className="text-success">{success}</p>}
          <button className="mt-4 btn btn-primary" disabled={saving}>Save</button>
        </form>

      </div >
    </AppLayout >
  )
}

export default Profile
