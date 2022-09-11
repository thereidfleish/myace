import Head from 'next/head'
import Image from 'next/image'
import Link from 'next/link'
import { logout, User } from '../lib/useUser'
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
    <section>
      <p className="dark:text-gray-700">{name}</p>
      <ul className="dark:text-gray-800 mt-1">
        {React.Children.map(children, child => {
          return <li>{child}</li>
        })}
      </ul>
    </section>
  )
}

function Footer() {
  return (
    <footer className="p-8 dark:bg-violet-400 dark:text-gray-800">

      <div className="grid grid-cols-2 content-center max-w-xl mx-auto">
        <FooterSection name="Company">
          <Link href="/"><a>Home</a></Link>
          <Link href="/contact"><a>Contact</a></Link>
        </FooterSection>

        <FooterSection name="Legal">
          <Link href="/privacy"><a>Privacy Policy</a></Link>
          <p className="dark:text-gray-700">© 2022 MyAce.ai LLC</p>
        </FooterSection>
      </div>

    </footer >
  )
}

export function MarketingLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <CommonHead />
      <div className="pb-28 dark:bg-gray-800 dark:text-gray-100 min-h-screen">

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

export function AppLayout({ user, children }: { user: User | undefined, children: React.ReactNode }) {
  // const { mutate } = useSWRConfig()
  return (
    <>
      <CommonHead />
      {!user && console.log("nope")}
      {user &&
        (
          <p>Welcome, {user.display_name}</p>
        )
      }
      {!user && (
        <p>this text is prerendered</p>
      )}
      <button onClick={logout}>logout</button>

      <main>
        <div className="mx-auto">{children}</div>
      </main>
    </>
  )
}
