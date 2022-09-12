import type { NextPage } from 'next'
import React, { useState } from 'react'
import { MarketingLayout } from '../components/Layout'
import useUser from '../lib/useUser'
import { LockClosedIcon, AtSymbolIcon } from '@heroicons/react/24/solid'
import Link from 'next/link'

const Login: NextPage = () => {
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState("")

  const { mutateUser, setToken } = useUser({
    redirectTo: '/apidocs',
  })

  const handleSubmit = async (e: React.FormEvent<HTMLFormElement>) => {
    e.preventDefault();
    // make the request
    const res = await fetch(process.env.NEXT_PUBLIC_BACKEND_ENDPOINT + '/login', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ email, password })
    })

    if (res.status == 200) {
      // parse the token
      const user = await res.json()
      setToken(user.token)
      mutateUser(user)
    } else {
      const error = await res.json()
      console.error(error)
      setError(error.error)
    }
  }

  return (

    <MarketingLayout>
      <div className="flex mt-32 lg:mt-40">

        {/* left text for large screens */}
        <div className="hidden lg:flex w-full lg:w-2/5 justify-around items-center">
          <div className="w-full mx-auto px-20 flex-col items-center space-y-6">
            <h2 className="font-bold text-4xl font-sans">Join Your Club</h2>
            <p className="mt-1">Request a demo for your fitness program and see how we can tailor MyAce to your needs.</p>
            <div className="flex justify-start mt-6">
              <Link href="/contact">
                <button className="bg-primary-content text-primary mt-4 px-4 py-2 rounded-2xl font-bold mb-2
                  hover:bg-primary hover:text-primary-content hover:-translate-y-1 transition-all duration-500">Contact Us</button>
              </Link>
            </div>
          </div>
        </div >

        <div className="flex lg:w-3/5 justify-center items-center space-y-8 w-full">
          {/* login card */}
          <div className="w-full px-3 sm:px-8 md:px-32 lg:px-24">
            <form className="bg-base-100 rounded-md shadow-2xl shadow-base-300 p-5" onSubmit={handleSubmit}>
              <h1 className="text-base-content font-bold text-2xl mb-1">Hey there</h1>
              <p className="text-sm font-normal text-base-content mb-8">Welcome back</p>

              <div className="flex items-center border-2 mb-8 py-2 px-3 rounded-2xl
                transition-all duration-75
                focus-within:outline focus-within:outline-accent-focus
                ">
                <AtSymbolIcon className="h-5 w-5 text-accent" />
                <input className="bg-base-100 pl-2 w-full outline-none border-none" type="email" name="email" placeholder="Email Address" onChange={e => setEmail(e.target.value)} required />
              </div>

              <div className="flex items-center border-2 mb-12 py-2 px-3 rounded-2xl
                transition-all duration-75
                focus-within:outline focus-within:outline-accent-focus
                ">
                <LockClosedIcon className="h-5 w-5 text-accent" />
                <input className="bg-base-100 pl-2 w-full outline-none border-none" type="password" name="password" id="password" placeholder="Password" onChange={e => setPassword(e.target.value)} required />
              </div>

              {error &&
                <p className="text-red-500">{error}</p>
              }

              <button type="submit" className="block w-full bg-primary mt-5 py-2 text-primary-content font-semibold mb-2 rounded-2xl
                hover:bg-primary-focus hover:-translate-y-1
                transition-all duration-300
                focus:outline focus:outline-1 focus:outline-accent
                ">Sign in</button>

              <div className="flex justify-between mt-4">
                {/* TODO: add forgot password functionality */}
                <a className="text-sm ml-2 text-gray-400 hover:text-accent cursor-pointer hover:-translate-y-1 duration-500 transition-all">Forgot Password ?</a>
                <Link href="/contact"><a className="text-sm ml-2 text-gray-400 hover:text-accent cursor-pointer hover:-translate-y-1 duration-500 transition-all">Don&#39;t have an account yet?</a></Link>
              </div>

            </form>
          </div>
        </div>
      </div>
    </MarketingLayout>
  )
}
export default Login
