import React from 'react'

export default function Team() {
  const team = [
    {
      name: 'Chris Price',
      description: 'Founder',
      picture: 'https://media-exp1.licdn.com/dms/image/C5603AQGd44T4D7sVMw/profile-displayphoto-shrink_400_400/0/1614116881005?e=1648684800&v=beta&t=UeHT6914T4I-5vFXlLzsmLNw6P-MO6W4cVTneabbX20',
      linkedin: 'https://www.linkedin.com/in/christopher-price-59a24b178/'
    },
    {
      name: 'Adler Weber',
      description: 'Backend',
      picture: "https://media-exp1.licdn.com/dms/image/C4E03AQF4q69YbpwsSQ/profile-displayphoto-shrink_400_400/0/1623430072214?e=1648684800&v=beta&t=siseUxh0WOouIRR0CyPKXWaNsJYEBj0IdU8kiBJOO8U",
      linkedin: 'https://www.linkedin.com/in/adler-weber-106a651ab/'
    },
    {
      name: 'Reid Fleishman',
      description: 'iOS',
      picture: "https://media-exp1.licdn.com/dms/image/C4D03AQEO4fkuZOwEUg/profile-displayphoto-shrink_400_400/0/1641232103208?e=1648684800&v=beta&t=5BsNg8Qj7qeG7MbasLh-zCSS1wgklrq8wE8rMjrlmpg",
      linkedin: 'https://www.linkedin.com/in/thereidfleish/'
    },
    {
      name: 'Andrew Chen',
      description: 'iOS',
      picture: "https://media-exp1.licdn.com/dms/image/C4E03AQGkzME7hPJWvw/profile-displayphoto-shrink_800_800/0/1608691026962?e=1649894400&v=beta&t=JC2mFl056mv0tGzFuasck1z9A-Jzz69MMJs1V2O6-Io",
      linkedin: 'https://www.linkedin.com/in/andrew-chen-210a72146/'
    },
    {
      name: 'Alex Godfrey',
      description: 'Web',
      picture: "https://media-exp1.licdn.com/dms/image/C5603AQEQkIucffHGSw/profile-displayphoto-shrink_800_800/0/1631155833068?e=1649894400&v=beta&t=7BBhXs2SbmHzOirMMMllR2y7REmVM6X1UOqd2Z0KL5M",
      linkedin: 'https://www.linkedin.com/in/alex-godfrey-91a7251b1/'
    },
  ]

  return (
    <div className="d-flex justify-content-center flex-wrap" style={{ padding: '0px 50px'}}>
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
