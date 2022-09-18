import type { NextPage } from 'next'
import Image from 'next/image'
import Link from 'next/link'
import Timeline from '../components/index/Timeline'
import About from '../components/index/About'
import Team from '../components/index/Team'
import { MarketingLayout } from '../components/Layout'

const Home: NextPage = () => {
  return (
    <MarketingLayout>
      <div className="mx-auto min-h-[95vh] flex flex-col items-center px-4 pt-24 pb-16 text-center md:py-36 md:px-10 lg:px-32 max-w-3xl">
        <h1 className="text-4xl font-bold leading-none sm:text-5xl">
          Next generation <span className="text-primary">athletic training</span> for your club
        </h1>
        <p className="px-8 my-8 text-lg">MyAce is social platform bringing coaches, players, and parents together.</p>
        <div className="mt-2 sm:mt-5 flex flex-wrap justify-center">
          <Link href="/login">
            <a className="m-2"><button className="h-full px-8 py-3 text-lg font-semibold rounded bg-primary text-primary-content hover:bg-primary-focus transition-all duration-300">Sign in</button></a>
          </Link>
          <Link href="/contact">
            <a className="m-2"><button className="h-full px-8 py-3 text-lg rounded bg-base-200 text-base-content border-2 border-base-300 hover:bg-base-300 transition-all duration-300">Contact Us</button></a>
          </Link>
        </div>
        <a href="https://apps.apple.com/us/app/myace/id1627934350?itsct=apps_box_badge&amp;itscg=30200" className="w-48 m-2 inline-block overflow-hidden rounded"> <Image src="/appstore-badges/black.svg" alt="Download on the App Store" style={{ borderRadius: "13px" }} layout="responsive" width="250" height="83" /* "250" */ /* height="70.5" *//* "83" */ /></a>
      </div>

      <Timeline />
      <About />
      <Team />
    </MarketingLayout>
  )
}

export default Home
