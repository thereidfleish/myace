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
      <div className="mx-auto min-h-[95vh] flex flex-col items-center px-4 py-16 text-center md:py-32 md:px-10 lg:px-32 xl:max-w-3xl">
        <h1 className="text-4xl font-bold leading-none sm:text-5xl">
          Next generation <span className="text-primary">athletic training</span> for your club
        </h1>
        <p className="px-8 mt-8 mb-12 text-lg">MyAce is social platform bringing coaches, players, and parents together.
        </p>
        <div className="flex flex-wrap justify-center py-2">
          <Link href="/login">
            <button className="px-8 py-3 m-2 text-lg font-semibold rounded bg-primary text-primary-content hover:bg-primary-focus transition-all duration-300">Sign in</button>
          </Link>
          <Link href="#timeline">
            <button className="px-8 py-3 m-2 text-lg border-2 rounded bg-base-200 text-base-content border-base-300 hover:bg-base-300 transition-all duration-300">Learn more</button>
          </Link>
          <a href="https://apps.apple.com/us/app/myace/id1627934350?itsct=apps_box_badge&amp;itscg=30200" className="w-48 m-2 inline-block overflow-hidden rounded"> <Image src="/appstore-badges/black.svg" alt="Download on the App Store" style={{ borderRadius: "13px" }} layout="responsive" width="250" height="83" /* "250" */ /* height="70.5" *//* "83" */ /></a>
        </div>
      </div>

      <Timeline />
      <About />
      <Team />
    </MarketingLayout>
  )
}

export default Home
