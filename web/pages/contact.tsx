import type { NextPage } from 'next'
import React from 'react'
import { MarketingLayout } from '../components/Layout'
import { EnvelopeIcon, PhoneArrowDownLeftIcon } from '@heroicons/react/24/solid'

function ContactURL({ icon, url, text }: { icon: React.ReactElement, url: string, text: string }) {
  return (
    <a href={url} className="mt-6 flex items-center">
      {/* circle background */}
      <div className="p-2 rounded-full flex items-center justify-center bg-primary">
        {/* overwrite the className of `icon` */}
        {React.cloneElement(icon, { className: "w-7 h-7 text-primary-content" })}
      </div>
      <span className="text-2xl ml-4">{text}</span>
    </a>
  )
}

const Contact: NextPage = () => {

  return (
    <MarketingLayout>
      <div className="max-w-2xl mx-auto">

        <h1 className="mt-16 mb-8 font-bold text-4xl">Get in touch</h1>
        <address className="not-italic sm:flex sm:justify-between">

          <div>
            <ContactURL icon={<EnvelopeIcon />} url="mailto:myaceai@gmail.com" text="myaceai@gmail.com" />
            <ContactURL icon={<PhoneArrowDownLeftIcon />} url="tel:18324441653" text="Call Chris" />
          </div>

          <div className="text-xl mt-12 sm:mt-6 sm:h-full sm:text-right">
            <strong>MyAce.ai LLC</strong><br />
            8 The Green Suite, A<br />
            Dover, Delaware 19901
          </div>

        </address>
        <h2 className="mt-12 mb-8 font-bold text-4xl">Beta Feedback</h2>
        <iframe width="100%" height="1300px" title="Beta Feedback Form" src="https://docs.google.com/forms/d/e/1FAIpQLSf9aY2-RUsSVp3pIBqvP6dmdqVJcC9Z6LOygBFlWmEY_f213Q/viewform?embedded=true" frameBorder="0">Loading…</iframe>
      </div>
    </MarketingLayout >
  )
}
export default Contact
