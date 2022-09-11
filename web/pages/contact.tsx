import type { NextPage } from 'next'
import React, { useState } from 'react'
import { MarketingLayout } from '../components/Layout'
import useUser, { setToken } from '../lib/useUser'
import { EnvelopeIcon, PhoneArrowDownLeftIcon } from '@heroicons/react/24/solid'
import Link from 'next/link'

function ContactURL({ icon, url, text }: { icon: React.ReactElement, url: string, text: string }) {
  return (
    <a href={url} className="mt-6 flex items-center">
      {/* circle background */}
      <div className="w-12 h-12 rounded-full flex items-center justify-center bg-violet-400">
        {/* overwrite the className of `icon` */}
        {React.cloneElement(icon, { className: "w-7 h-7" })}
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
        <address className="not-italic grid grid-flow-row-dense grid-cols-2">
          <ContactURL icon={<EnvelopeIcon />} url="mailto:myaceai@gmail.com" text="myaceai@gmail.com" />
          <div className="text-xl row-span-2 text-right">
            <strong>MyAce.ai LLC</strong><br />
            8 The Green Suite, A<br />
            Dover, Delaware 19901
          </div>
          <ContactURL icon={<PhoneArrowDownLeftIcon />} url="tel:18324441653" text="Call Chris" />
        </address>
        <h2 className="mt-16 mb-8 font-bold text-4xl">Beta Feedback</h2>
        <iframe width="100%" height="1300px" title="Beta Feedback Form" src="https://docs.google.com/forms/d/e/1FAIpQLSf9aY2-RUsSVp3pIBqvP6dmdqVJcC9Z6LOygBFlWmEY_f213Q/viewform?embedded=true" frameBorder="0">Loading…</iframe>
      </div>
    </MarketingLayout >
  )
}
export default Contact
