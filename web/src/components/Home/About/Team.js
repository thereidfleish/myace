import React from 'react'

export default function Team() {
  const team = [
    {
      name: 'Chris Price',
      description: 'Founder',
      picture: process.env.PUBLIC_URL + "/team/chris.jpg",
      linkedin: 'https://www.linkedin.com/in/christopher-price-59a24b178/'
    },
    {
      name: 'Adler Weber',
      description: 'Backend',
      picture: process.env.PUBLIC_URL + "/team/adler.jpg",
      linkedin: 'https://www.linkedin.com/in/adler-weber-106a651ab/'
    },
    {
      name: 'Cameron Goddard',
      description: 'Backend',
      picture: process.env.PUBLIC_URL + "/team/cameron.jpg",
      linkedin: 'https://www.linkedin.com/in/cameron-goddard-ab7537222/'
    },
    {
      name: 'Reid Fleishman',
      description: 'iOS',
      picture: process.env.PUBLIC_URL + "/team/reid.jpg",
      linkedin: 'https://www.linkedin.com/in/thereidfleish/'
    },
    {
      name: 'Andrew Chen',
      description: 'iOS',
      picture: process.env.PUBLIC_URL + "/team/andrew.jpg",
      linkedin: 'https://www.linkedin.com/in/andrew-chen-210a72146/'
    },
  ]

  return (
    <div className="d-flex justify-content-center flex-wrap" style={{ padding: '0px 50px' }}>
      {
        team.map((member, i) => {
          return (
            <div style={{ margin: '20px' }} key={i} className="d-flex flex-column align-items-center">
              <h4 style={{ lineHeight: '0.6' }}>{member.name}</h4>
              <h5>{member.description}</h5>
              <a target="_blank" rel="noreferrer" href={member.linkedin}>
                <img
                  style={{
                    width: '200px',
                    borderRadius: '50%',
                    border: '3px solid #8AD28A',
                    cursor: 'pointer'
                  }}
                  src={member.picture}
                  alt={member.name}
                />
              </a>
            </div>
          )
        })
      }
    </div>
  )
}
