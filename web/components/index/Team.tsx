import React from 'react'
import Image from 'next/image'

function Member({ name, description, linkedin, picture }: { name: string, description: string, linkedin: string, picture: string }) {
  return (
    <div className="grid grid-cols-2 sm:block sm:mx-4 items-center mt-4 sm:mt-6">
      <a target="_blank" rel="noreferrer" href={linkedin}>
        <div className="flex items-center rounded-full border-4 border-primary">
          <Image src={picture} alt={name} width="200" height="200" className="rounded-full" />
        </div>
      </a>

      {/* label for mobile */}
      <div className="ml-6 sm:ml-0 sm:text-center">
        <h4 className="font-bold text-xl">{name}</h4>
        <p>{description}</p>
      </div>

    </div>
  )
}

export default function Team() {
  const members = [
    {
      name: 'Chris Price',
      description: 'Founder',
      picture: "/team/chris.jpg",
      linkedin: 'https://www.linkedin.com/in/christopher-price-59a24b178/'
    },
    {
      name: 'Adler Weber',
      description: 'Backend & Web',
      picture: "/team/adler.jpg",
      linkedin: 'https://www.linkedin.com/in/adler-weber-106a651ab/'
    },
    {
      name: 'Cameron Goddard',
      description: 'Backend',
      picture: "/team/cameron.jpg",
      linkedin: 'https://www.linkedin.com/in/cameron-goddard-ab7537222/'
    },
    {
      name: 'Reid Fleishman',
      description: 'iOS',
      picture: "/team/reid.jpg",
      linkedin: 'https://www.linkedin.com/in/thereidfleish/'
    },
    {
      name: 'Andrew Chen',
      description: 'Android & iOS',
      picture: "/team/andrew.jpg",
      linkedin: 'https://www.linkedin.com/in/andrew-chen-210a72146/'
    },
  ]

  return (
    <section className="mt-40 max-w-4xl mx-auto">
      <h2 className="font-bold text-4xl">Meet the team</h2>
      <div className="mt-8 flex justify-center flex-wrap">
        {
          members.map((member, i) => {
            return (
              <Member
                name={member.name}
                description={member.description}
                linkedin={member.linkedin}
                picture={member.picture}
                key={i}
              />
            )
          })
        }
      </div>
    </section>
  )
}
