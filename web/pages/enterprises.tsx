import type { NextPage } from 'next'
import React, { ChangeEvent, useEffect, useState } from 'react'
import useSWR from 'swr'
import { AppLayout } from '../components/Layout'
import useUser from '../lib/useUser'
import { PlusIcon, TrashIcon } from '@heroicons/react/24/solid'

export type Enterprise = {
  enterprise_id: string,
  name: string,
  website: string,
  support_email: string,
  support_phone: string,
  logo: string,
  created_at: string,
}

type createEnterpriseReq = {
  name: string,
  website?: string,
  support_email?: string,
  support_phone?: string,
}

type enterprisesResponse = {
  enterprises: Enterprise[]
}

// a reusable data hook to access 
function useEnterprisesRes(token: string) {
  const { data: enterprisesRes, mutate: mutateEnterprisesRes, error } = useSWR<enterprisesResponse>(

    // if token is empty string, do not make the request
    token == '' ? null :
      [
        process.env.NEXT_PUBLIC_BACKEND_ENDPOINT + '/enterprises',
        token
      ])

  return {
    enterprisesRes,
    mutateEnterprisesRes,
    error,
  }
}

function ModalInput({ type = "text", label, value, setState, required = false }: { type?: string, label: string, value: string, setState: any, required?: boolean }) {

  return (
    <div className="form-control w-full max-w-xs my-2">
      <label className="label"><span className="label-text">{label}</span></label>
      <input type={type} value={value} className="input input-bordered w-full max-w-xs" onChange={setState} required={required} />
    </div>
  )
}

function AddEnterpriseForm({ setModal }: { setModal: React.Dispatch<React.SetStateAction<boolean>> }) {
  const { token } = useUser()
  const { enterprisesRes, mutateEnterprisesRes } = useEnterprisesRes(token)
  const [reqBody, setReqBody] = useState<createEnterpriseReq>({
    name: ''
  })
  const [error, setError] = useState('')
  const [submitting, setSubmitting] = useState(false)

  const onSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();

    // clear status messages
    setError("")
    setSubmitting(true);

    // make the request
    const res = await fetch(process.env.NEXT_PUBLIC_BACKEND_ENDPOINT + '/enterprises', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
      },
      body: JSON.stringify(reqBody)
    })

    // handle response
    if (res.status == 200) {
      const enterprise = await res.json()
      console.log(enterprise)
      setModal(false)
      // add new enterprise to application state
      if (enterprisesRes) {
        enterprisesRes.enterprises.push(enterprise)
        mutateEnterprisesRes(enterprisesRes)
      }
    } else {
      const error = await res.json()
      console.error(error)
      setError(error.error)
    }
    setSubmitting(false)
  }
  return (
    <>
      <h2>Create New Enterprise</h2>
      <form onSubmit={onSubmit}>
        <ModalInput label="Name" value={reqBody.name} setState={(e: ChangeEvent<HTMLInputElement>) => {
          setReqBody({ ...reqBody, name: e.target.value })
        }} required />
        <ModalInput label="Website URL" value={reqBody.website || ''} setState={(e: ChangeEvent<HTMLInputElement>) => {
          setReqBody({ ...reqBody, website: e.target.value })
        }} />
        <ModalInput label="Support Email Address" type="email" value={reqBody.support_email || ''} setState={(e: ChangeEvent<HTMLInputElement>) => {
          setReqBody({ ...reqBody, support_email: e.target.value })
        }} />
        <ModalInput label="Support Phone Number" type="phone" value={reqBody.support_phone || ''} setState={(e: ChangeEvent<HTMLInputElement>) => {
          setReqBody({ ...reqBody, support_phone: e.target.value })
        }} />
        {error &&
          <p className="text-error">{error}</p>}
        <button className="mt-4 btn btn-primary" disabled={submitting}>Create</button>
      </form>
    </>
  )
}

// a modal button that reveals an "add enterprise" form
function AddEnterpriseBtn() {
  const [hidden, setHidden] = useState(true)
  const [isModalOpen, setModalOpen] = useState(false)

  useEffect(() => {
    // TODO: only display if user has permission to add an enterprise
    setHidden(false)
  }, [])

  if (hidden) return <></>
  return (
    <>
      {/* modal button */}
      <label htmlFor="create-enterprise-modal" className="btn btn-primary btn-circle btn-lg modal-button">
        <PlusIcon />
      </label>

      <input type="checkbox" id="create-enterprise-modal" className="modal-toggle" checked={isModalOpen} onChange={() => setModalOpen(!isModalOpen)} />
      <label htmlFor="create-enterprise-modal" className="modal cursor-pointer">
        <label className="modal-box relative" htmlFor="">
          <AddEnterpriseForm setModal={setModalOpen} />
        </label>
      </label>
    </>
  )
}

// a card component containing all public information about an enterprise
function EnterpriseCard(enterprise: Enterprise) {
  const { token } = useUser()
  const { enterprisesRes, mutateEnterprisesRes } = useEnterprisesRes(token)

  const handleDeleteEnterprise = async (enterprise_id: string) => {
    // make the request
    const res = await fetch(process.env.NEXT_PUBLIC_BACKEND_ENDPOINT + '/enterprises/' + enterprise_id, {
      method: 'DELETE',
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ' + token
      },
    })

    // handle response
    if (res.status == 204) {
      // delete enterprise from application state
      if (enterprisesRes) {
        enterprisesRes.enterprises = enterprisesRes.enterprises.filter(ent => ent.enterprise_id != enterprise_id)
        mutateEnterprisesRes(enterprisesRes)
      }
    } else {
      const error = await res.json()
      console.error(error)
    }
  }


  return (
    <div className="my-6 mx-3 card w-96 bg-neutral text-neutral-content shadow-xl">
      <div className="card-body">
        <header className="flex justify-between">
          <h2 className="card-title">{enterprise.name}</h2>
          <div className="card-actions justify-end">
            <button className="btn btn-square text-error p-1.5" onClick={() => handleDeleteEnterprise(enterprise.enterprise_id)}>
              <TrashIcon />
            </button>
          </div>
        </header>
        <p>ID: {enterprise.enterprise_id}</p>
        <p>Created: {enterprise.created_at}</p>
        <p>Logo: {enterprise.logo}</p>
        <p>Website: {enterprise.website}</p>
        <p>Email: {enterprise.support_email}</p>
        <p>Phone: {enterprise.support_phone}</p>
      </div>
    </div>
  )
}

const Enterprises: NextPage = () => {
  // Fetch the user client-side
  const { user, token } = useUser()
  const { enterprisesRes } = useEnterprisesRes(token)

  // Server-render loading state
  if (!user) {
    return <AppLayout>Loading...</AppLayout>
  }

  return (
    <AppLayout padding={false}>
      <div>
        <h1 className="text-2xl">MyAce Enterprises</h1>
        <AddEnterpriseBtn />
      </div>
      <ul className="flex flex-wrap justify-evenly content-evenly">
        {
          enterprisesRes?.enterprises.map((enterprise, i) => {
            return (
              <EnterpriseCard
                {...enterprise}
                key={i}
              />
            )
          })
        }
      </ul>
    </AppLayout>
  )
}
export default Enterprises
