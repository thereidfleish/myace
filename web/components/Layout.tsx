import Head from 'next/head'
import Image from 'next/image'
import Link from 'next/link'
import useUser, { logout } from '../lib/useUser'
import React from 'react'

// a common Head component used in all layouts
function CommonHead() {
  return (
    <Head>
      <title>MyAce</title>
      <meta name="description" content="MyAce is an all-in-one solution to bring social tools to athletic clubs and teams." />
      <link rel="icon" href="/logo.svg" />
    </Head>
  )
}

function FooterSection({ name, children }: { name: string, children: React.ReactNode }) {
  return (
    <section className="text-base-dark-700">
      <p className="font-medium">{name}</p>
      <ul className="text-base-dark-700 mt-2">
        {React.Children.map(children, child => {
          return <li className="mt-1">{child}</li>
        })}
      </ul>
    </section>
  )
}

function Footer() {
  return (
    <footer className="p-8 bg-primary-dark text-base-dark-800">

      <div className="grid grid-cols-2 content-center max-w-xl mx-auto">
        <FooterSection name="Company">
          <Link href="/"><a className="underline">Home</a></Link>
          <Link href="/contact"><a className="underline">Contact</a></Link>
        </FooterSection>

        <FooterSection name="Legal">
          <Link href="/privacy"><a className="underline">Privacy Policy</a></Link>
          <p>© 2022 MyAce.ai LLC</p>
        </FooterSection>
      </div>

    </footer >
  )
}

export function MarketingLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <CommonHead />
      <div className="pb-28 bg-base-dark-800 text-gray-100 min-h-screen">

        {/* header with logo */}
        <header>
          <div className="p-4 container mx-auto flex max-w-6xl">
            <Link href="/">
              <a className="flex">
                <Image src="/logo.svg" alt="MyAce logo" width="32" height="32" />
                <p className="ml-3 text-2xl font-bold sm:text-2xl">MyAce</p>
              </a>
            </Link>
          </div>
        </header>

        {/* main content */}
        <main className="container mx-auto max-w-6xl px-4 sm:px-8">
          {children}
        </main>
      </div>
      <Footer />
    </>
  )
}

export function AppLayout({ children, padding = true }: { children: React.ReactNode, padding?: boolean }) {
  // const { mutate } = useSWRConfig()
  const { user, setToken } = useUser()

  return (
    <>
      <CommonHead />
      <header className="h-9 px-2 bg-base-dark-800 flex justify-between items-center">
        {user &&
          (
            <p>Welcome, {user.username}</p>
          )
        }
        {
          !user && (
            <p>this text is prerendered</p>
          )
        }
        <div className="flex">
          <Link href="/apidocs"><a>docs</a></Link>
          <Link href="/profile"><a className="ml-2">profile</a></Link>
          <button className="ml-2" onClick={() => logout(setToken)}>logout</button>
        </div>
      </header>

      <main className={"bg-base-dark-600" + (padding ? " p-4" : "")}>
        <div className="mx-auto">{children}</div>
      </main >
    </>
  )
}
